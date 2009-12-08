(function()
{
  var handle_non_select_inputs = function(inputs)
  {
    for(var i = 0; i < inputs.length; i++)
    {
      if(/^radio|checkbox$/.test(inputs[i].type))
      {
        inputs[i].checked = true;
      }
      else if(/^text|password|$/.test(inputs[i].type))
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
          inputs[i].value = "testString";
        }
      }
    }
  };

  handle_non_select_inputs(document.getElementsByTagName('input'));
  handle_non_select_inputs(document.getElementsByTagName('textarea'));

  var inputs = document.getElementsByTagName('select');
  for(var i = 0; i < inputs.length; i++)
  {
    var opts = inputs[i].options;
    for(var j = 0; j < opts.length; j++)
    {
      if(opts[j].value != '')
      {
        inputs[i].selectedIndex = j;
      }
    }
  };
})();
void(0);
