$.fn.colorFade = function(color, duration) {
  if (duration == null) {
    duration = 500;
  }
  return this.each(function() {
    var original;
    original = $(this).css("color");
    $(this).mouseover(function() {
      return $(this).stop().animate({
        color: color
      }, duration);
    });
    return $(this).mouseout(function() {
      return $(this).stop().animate({
        color: original
      }, duration);
    });
  });
};

$(function() {
	$("#main-nav ul li a").each(function() {
		return $(this).colorFade("#787878", 1200);
	});

	var currentDate = new Date();

	$("#copyright-year").text(currentDate.getFullYear());

	$("#contact-form-submit").on("click", function(event) {
		event.preventDefault();

		$("#contact-form-ajax").val("1");

		$.post($("#contact-form").attr("action"), $("#contact-form").serialize(), function(data, textStatus, jqXHR) {
			console.log(data);
		});
	});
});


