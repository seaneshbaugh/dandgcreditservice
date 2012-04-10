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

var showAlertMessage = function(alertMessageTitle, alertMessageBody, alertMessageClass) {
	$("#alert-message-title").empty();

	$("#alert-message-title").append(alertMessageTitle);

	$("#alert-message-body").empty();

	$("#alert-message-body").append(alertMessageBody);

	$("#alert-message").removeClass();

	$("#alert-message").addClass(alertMessageClass);

	$("#alert-message").css({ top: (Math.round($(window).height() / 2) - Math.round($("#alert-message").height() / 2)) + "px" });

	$("#alert-message").css({ left: (Math.round($(window).width() / 2) - Math.round($("#alert-message").width() / 2)) + "px" });

	$("#alert-message").stop().show().css({ opacity: 1.0 }).fadeTo(8000, 0.0);
}

$(function() {
	$("#main-nav ul li a").each(function() {
		return $(this).colorFade("#787878", 1200);
	});

	var currentDate = new Date();

	$("#copyright-year").text(currentDate.getFullYear());

	$("#alert-message").on("mouseover", function(event) {
		if ($(this).css("opacity") !== "0") {
			$(this).stop().css({ opacity: 1.0 });
		}
	});

	$("#alert-message").on("mouseout", function(event) {
		$(this).fadeTo(2000, 0.0, function() {
			$("#alert-message-title").empty();
			$("#alert-message-body").empty();
		});
	});

	var validator = new FormValidator("contact-form",
		[{
			name: "name",
			display: "Name",
			rules: "required|max_length[255]"
		}, {
			name: "email_address",
			display: "Email Address",
			rules: "required|valid_email|max_length[255]"
		}, {
			name: "phone_number",
			display: "Phone Number",
			rules: "required|callback_valid_phone"
		}, {
			name: "message",
			display: "Message",
			rules: "required|max_length[65535]"
		}],
		function(errors, event) {
			if (event && event.preventDefault) {
				event.preventDefault();
			} else if (event) {
				event.returnValue = false;
			}

			if (errors.length > 0) {
				showAlertMessage("Error!", errors.join("<br />"), "error");
			} else {
				$("#contact-form-submit").attr("disabled", true);

				$("#contact-form-ajax").val("1");

				$.post($("#contact-form").attr("action"), $("#contact-form").serialize(), function(data, textStatus, jqXHR) {
					console.log(data);
					console.log(textStatus);
					console.log(jqXHR);

					var alertMessageClass;

					if (jqXHR.status === 200) {
						alertMessageClass = "success";

						$("#contact-form-name").val("");
						$("#contact-form-email-address").val("");
						$("#contact-form-phone-number").val("");
						$("#contact-form-message").val("");
					} else {
						alertMessageClass = "error";
					}

					showAlertMessage(data.response_title, data.response_message, alertMessageClass);

					$("#contact-form-submit").attr("disabled", false);
				});
			}
		}
	);

	validator.registerCallback("valid_phone", function(value) {
		return /^((([0-9]{1})*[- .(]*([0-9]{3})[- .)]*[0-9]{3}[- .]*[0-9]{4})+)*$/.test(value);
	}).setMessage("valid_phone", "The Phone Number field must be a valid phone number.");
});
