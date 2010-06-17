#!/usr/bin/ruby
=begin
Depends on recent mplayer with libfaac and libx264 installed before compiling/installing mplayer.
Also, to read AAC audio, libfaad, and to read MP3 audio, libmp3lame, must be installed before compiling/installing mplayer.
If these requirements are not met, don't even try to run this script.

Mencoder may warn about "REMEMBER: MEncoder's libavformat muxing is presently broken"; this is irrelevant for encoding videos in H.264 for the iPod Touch/iPhone,
as they don't use B-frames.

Usage:
encode.rb <input filename> <options>

Options are:
  --no-encode      Prints the encoding command, but doesn't run it
  --ipod           Encodes for the ipod nano 5g instead of ipod touch.
#  --more-keyframes Adds a keyframe every 3 seconds, instead of every 10 (approx.) seconds. Makes seeking better, but also makes file size larger.
=end

class Float
  def round_nearest_even_integer
    (self / 2.0 + 0.5).to_i * 2
  end
end

allowed_opts = %w(--no-encode --more-keyframes --ipod)

opts = ARGV & allowed_opts

(ARGV - allowed_opts).each do |movie|
  if ARGV.include?("--ipod")
    max_output_width = 376
    max_output_height = 240
  else
    max_output_width = 480
    max_output_hieght = 320
  end

  movie_path = File.expand_path(movie)
  escaped_movie_path = movie_path.gsub(/([ \[\]\(\)'"])/) { |r| "\\#{$1}" } #shell escape the input filename

  #set the output filename to only contain safe characters, and tp have the m4v extension
  output_filename = "#{File.basename(movie).gsub(/\..*{3}/, '').gsub(/[^A-z0-9_-]/, '_')}.m4v"

=begin
  get some information about the input movie; the options are:
  * -identify tells mplayer to print the info on the movie that we need
  * -frames 0 tells mplayer to quit as soon as we have the info
  * -nomsgcolor stops mplayer form outputting special characters that print nice colours in the shell; without this,
    it'd be more of a pain to read the data we want.
=end
  movie_info = IO.popen("mplayer -identify -frames 0 -nomsgcolor #{escaped_movie_path} &2>1") { |s| s.read }
  lines = movie_info.split("\n")

=begin
  get the reported width, height, and aspect ratio of the input movie. If the aspect is not 0,
  then we get the width of the movie by multiplying the height by the aspect ratio; this avoids problems when the movie needs
  to be scaled horizontally before being displayed. If he aspect ratio is 0, then the reports height is used as the height of the input.
=end  
  height = lines.detect { |l| l =~ /^ID_VIDEO_HEIGHT=/ }.split("=").last.to_i
  reported_width = lines.detect { |l| l =~ /^ID_VIDEO_WIDTH=/ }.split("=").last.to_i
  aspect = lines.detect { |l| l =~ /^ID_VIDEO_ASPECT=/ }.split("=").last.to_f
  #puts "reported_height: #{height}, reported_width: #{reported_width}, aspect: #{aspect}"
  
  width = aspect > 0 ? height * aspect : reported_width

  #Resize
  true_ratio = height / max_output_height.to_f
  new_height = (height / true_ratio).round_nearest_even_integer
  new_width = (width / true_ratio).round_nearest_even_integer
  
  if new_height > max_output_height || new_width > max_output_width
    true_ratio = width / max_output_width.to_f
    new_height = (height / true_ratio).round_nearest_even_integer
    new_width = (width / true_ratio).round_nearest_even_integer
  end
  #End resize
  
  width = new_width
  height = new_height

  height_expand = -(240 - height)
  width_expand = -(376 - width)

  subs = !!lines.detect { |l| l =~ /^ID_SUBTITLE_ID=/ }

=begin
  The code that follows is the really important part. The code above is just to get the right widths and heights to scale to, and to work out
  whether to convert hardsubs => softsubs or not.

  video_filter_cmd scales the video input to a fixed output size of 480x320 (the native resolution of the iPod Touch / iPhone).
  Specifically, the options work as follows:
  * the scale option sets the output size to be 480x(scaled height if input video);
  * the expand option adds black bars to the video to make it 320 pixels high;
  * the harddup option ensures that, when the input video has soft-duplicated frames, the output video has the frame actually duplicated
    (this is needed otherwise the audio loses syncronization with the video);
  * the noskip option make sure the no video frames are skipped (without this, audio loses sync with the video);
  * and the mc 0 otion sets the amount of drift between the audio and the video to nothing, to ensure the audio syncs with the video.

  output_format_cmd does the work needed to make sure the video/audio output will actually play on the iPod Touch/iPhone. THe options are as follows:
  * -oac faac tells mencoder to encode AAC audio on the output;
  * I don't actually know mpeg=4, object=2, and raw do, but those options have been reccomended, and it works with them so I've left it;
    I suspect they are a part of ensuring the audio is 'LC' or Low Complexity;
  * The br=128 option sets the audio bitrate to 128kb/s, which AFAIK makes sure the audio is LC;
  * -ovc x264 tells mencoder to encode the video as H.264;
  * bframes=0,nocabac,global_header,no8x8dct,weightp=0 are the options needed to make the video output H.264 Baseline, as opposed to H.264 Main etc.
    Without these options, the video will not play on an iPod Touch/iPhone.

  subs_cmd controls the way the subtitles are converted from softsubs to hardsubs, if the input movie has softsubs. The options are as follows:
  * -subfont-autoscale 0 tells mencoder to not scale the subtitle font size automatically;
  * -subfont-text-scale 20 sets the font size of the subtitles to be %20 the height of the movie.
  * -subpos 99 puts the bottom edge of the subtitles at 99% from the top of the movie;
  * -subfont-blur 2 puts a 2 pixel gaussian blur around the subtitle text;
  * -subfont-outline 1 puts a 1 pixel outline around the subtitle text.

  The mencoder command itself has a -of lavf option; this tells mencoder to use the lavf encoder (part of ffmpeg) to encode the movie; this allows us
  to set the options above.
  
  If the movie won't even copy or play at all on the device, outut_format_cmd is the first thing to change.
=end

  video_filter_cmd = "-vf scale=#{width}:#{height},expand=#{width_expand}:#{height_expand}:#{subs ? '0:0' : ':'}:1,harddup -noskip -mc 0"
  output_format_cmd = "-oac faac -faacopts mpeg=4:object=2:raw:br=128 -ovc x264 -x264encopts bframes=0:nocabac:global_header:no8x8dct:weightp=0"
  subs_cmd = subs ? '-subfont-autoscale 0 -subfont-text-scale 20 -subpos 99 -subfont-blur 2 -subfont-outline 1' : ''
  
  cmd = "mencoder -o #{output_filename} -of lavf #{video_filter_cmd} #{output_format_cmd} #{subs_cmd} '#{movie}' &2>1"
  puts cmd
  system cmd unless opts.include?('--no-encode')

=begin
  If mencoder crashes with a segfault, then try this instead of the above section. This script has worked for me in cases where the above has not.
  Note that you need to install ffmpeg additionally, and separately, from mencoder. FFMpeg needs libfaac, libfaad, and libx264 compiled in.
=end
=begin
  File.delete("/tmp/movie.avi") if File.exists?("/tmp/movie.avi")

  cmd = "mencoder -o /tmp/movie.m4v -of lavf #{video_filter_cmd} #{output_format_cmd} '#{movie}' &2>1"
  puts cmd
  system cmd unless opts.include?('--no-encode')

  cmd = "ffmpeg -i /tmp/movie.avi -acodec copy -vcodec copy #{output_filename}"
  puts cmd
  system cmd unless opts.include?('--no-encode')

  File.delete("/tmp/movie.avi") if File.exists?("/tmp/movie.avi")
=end
end