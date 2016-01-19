(function(){
  "use strict";

  var current_line_num = null;
  var current_line_code = null;

  function clearCurrentLine()
  {
    if(current_line_num)
    {
      current_line_num.removeClass("current-line-number");
      current_line_code.removeClass("current-line");
    }
  }

  function mouseCallback(e)
  {
    clearCurrentLine();

    current_line_num = $(this.children[0]);
    current_line_code = $(this.children[1]);

    current_line_num.addClass("current-line-number");
    current_line_code.addClass("current-line");
  }

  window.addEventListener("load", function() {
    $("#paste-content tr").on("mouseover", mouseCallback);
    $("#paste-content").on("mouseout", clearCurrentLine);
  });
})();
