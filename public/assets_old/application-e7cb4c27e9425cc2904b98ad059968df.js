$(function(){$(".fg-button").hover(function(){$(this).removeClass("ui-state-default").addClass("ui-state-focus")},function(){$(this).removeClass("ui-state-focus").addClass("ui-state-default")}),$("#hierarchy").click(function(){return!1}),$.get("/dashboard/navigation",function(a){$("#hierarchy").menu({content:a,showSpeed:400}),$("#hierarchy").removeClass("hidden")})});