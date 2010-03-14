(function()
{
  var handle_inputs = function(inputs)
  {
    for(var i = 0; i < inputs.length; i++)
    {
      if(inputs[i].tagName.toLowerCase() == 'select')
      {
        inputs[i].selectedIndex = inputs[i].options.length - 1;
      }
      else if(/^radio|checkbox$/.test(inputs[i].type))
      {
        inputs[i].checked = true;
      }
      else if(/^text|password$/.test(inputs[i].type) || inputs[i].tagName.toLowerCase() == 'textarea')
      {
        if(/email/i.test(inputs[i].name))
        {
          inputs[i].value = "t" + Math.round(Math.random()*10000) + "@mailinator.com";
        }
        else if(/date/i.test(inputs[i].name))
        {
          inputs[i].value = (new Date()).toDateString();
        }
        else
        {
          inputs[i].value = "test";
        }
      }
    }
  };
  
  function fill_window(w)
  {
    handle_inputs(w.document.getElementsByTagName('input'));
    handle_inputs(w.document.getElementsByTagName('textarea'));
    handle_inputs(w.document.getElementsByTagName('select'));

    if(w.frames.length > 0)
    {
      for(var i = 0; i < w.frames.length; i++)
      {
        fill_window(w.frames[i]);
      }
    }
  };
  
  fill_window(window.top);
})();
void(0);
