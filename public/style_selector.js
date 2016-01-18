(function(){
  "use strict";

  var selector_dropdown;
  var grp_stylesheets;
  var active_style;

  function setActiveStyle(id) {
    selector_dropdown.value = id;
    Cookies.set("active_style", id);
    active_style = id;

    for(var i = grp_stylesheets.length; i -- > 0;)
    {
      grp_stylesheets.item(i).setAttribute("rel",
        (grp_stylesheets.item(i).getAttribute("name") == id) ? "stylesheet" : "alternate stylesheet");
    }
  }

  window.addEventListener("load", function() {
    selector_dropdown = document.getElementById("style-selector");
    grp_stylesheets = document.getElementsByClassName("grp-stylesheet");

    active_style = Cookies.get("active_style");
    if(!active_style)
      setActiveStyle("classic");

    selector_dropdown.value = active_style;

    selector_dropdown.addEventListener("change", function() {
      setActiveStyle(selector_dropdown.value);
    });
  });
})();
