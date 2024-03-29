(function ($) {
    $().ajaxSend(function (a, xhr, s) {
        xhr.setRequestHeader("Accept", "text/javascript, text/html, application/xml, text/xml, */*")
    })
})(jQuery);
(function ($) {
    $.fn.reset = function () {
        return this.each(function () {
            if (typeof this.reset == "function" || (typeof this.reset == "object" && !this.reset.nodeType)) {
                this.reset()
            }
        })
    };
    $.fn.enable = function () {
        return this.each(function () {
            this.disabled = false
        })
    };
    $.fn.disable = function () {
        return this.each(function () {
            this.disabled = true
        })
    }
})(jQuery);
(function ($) {
    $.extend({
        fieldEvent: function (el, obs) {
            var field = el[0] || el,
                e = "change";
            if (field.type == "radio" || field.type == "checkbox") {
                e = "click"
            } else {
                if (obs && field.type == "text" || field.type == "textarea") {
                    e = "keyup"
                }
            }
            return e
        }
    });
    $.fn.extend({
        delayedObserver: function (delay, callback) {
            var el = $(this);
            if (typeof window.delayedObserverStack == "undefined") {
                window.delayedObserverStack = []
            }
            if (typeof window.delayedObserverCallback == "undefined") {
                window.delayedObserverCallback = function (stackPos) {
                    observed = window.delayedObserverStack[stackPos];
                    if (observed.timer) {
                        clearTimeout(observed.timer)
                    }
                    observed.timer = setTimeout(function () {
                        observed.timer = null;
                        observed.callback(observed.obj, observed.obj.formVal())
                    }, observed.delay * 1000);
                    observed.oldVal = observed.obj.formVal()
                }
            }
            window.delayedObserverStack.push({
                obj: el,
                timer: null,
                delay: delay,
                oldVal: el.formVal(),
                callback: callback
            });
            var stackPos = window.delayedObserverStack.length - 1;
            if (el[0].tagName == "FORM") {
                $(":input", el).each(function () {
                    var field = $(this);
                    field.bind($.fieldEvent(field, delay), function () {
                        observed = window.delayedObserverStack[stackPos];
                        if (observed.obj.formVal() == observed.obj.oldVal) {
                            return
                        } else {
                            window.delayedObserverCallback(stackPos)
                        }
                    })
                })
            } else {
                el.bind($.fieldEvent(el, delay), function () {
                    observed = window.delayedObserverStack[stackPos];
                    if (observed.obj.formVal() == observed.obj.oldVal) {
                        return
                    } else {
                        window.delayedObserverCallback(stackPos)
                    }
                })
            }
        },
        formVal: function () {
            var el = this[0];
            if (el.tagName == "FORM") {
                return this.serialize()
            }
            if (el.type == "checkbox" || self.type == "radio") {
                return this.filter("input:checked").val() || ""
            } else {
                return this.val()
            }
        }
    })
})(jQuery);
(function ($) {
    $.fn.extend({
        visualEffect: function (o) {
            e = o.replace(/\_(.)/g, function (m, l) {
                return l.toUpperCase()
            });
            return eval("$(this)." + e + "()")
        },
        appear: function (speed, callback) {
            return this.fadeIn(speed, callback)
        },
        blindDown: function (speed, callback) {
            return this.show("blind", {
                direction: "vertical"
            }, speed, callback)
        },
        blindUp: function (speed, callback) {
            return this.hide("blind", {
                direction: "vertical"
            }, speed, callback)
        },
        blindRight: function (speed, callback) {
            return this.show("blind", {
                direction: "horizontal"
            }, speed, callback)
        },
        blindLeft: function (speed, callback) {
            this.hide("blind", {
                direction: "horizontal"
            }, speed, callback);
            return this
        },
        dropOut: function (speed, callback) {
            return this.hide("drop", {
                direction: "down"
            }, speed, callback)
        },
        dropIn: function (speed, callback) {
            return this.show("drop", {
                direction: "up"
            }, speed, callback)
        },
        fade: function (speed, callback) {
            return this.fadeOut(speed, callback)
        },
        fadeToggle: function (speed, callback) {
            return this.animate({
                opacity: "toggle"
            }, speed, callback)
        },
        fold: function (speed, callback) {
            return this.hide("fold", {}, speed, callback)
        },
        foldOut: function (speed, callback) {
            return this.show("fold", {}, speed, callback)
        },
        grow: function (speed, callback) {
            return this.show("scale", {}, speed, callback)
        },
        highlight: function (speed, callback) {
            return this.show("highlight", {}, speed, callback)
        },
        puff: function (speed, callback) {
            return this.hide("puff", {}, speed, callback)
        },
        pulsate: function (speed, callback) {
            return this.show("pulsate", {}, speed, callback)
        },
        shake: function (speed, callback) {
            return this.show("shake", {}, speed, callback)
        },
        shrink: function (speed, callback) {
            return this.hide("scale", {}, speed, callback)
        },
        squish: function (speed, callback) {
            return this.hide("scale", {
                origin: ["top", "left"]
            }, speed, callback)
        },
        slideUp: function (speed, callback) {
            return this.hide("slide", {
                direction: "up"
            }, speed, callback)
        },
        slideDown: function (speed, callback) {
            return this.show("slide", {
                direction: "up"
            }, speed, callback)
        },
        switchOff: function (speed, callback) {
            return this.hide("clip", {}, speed, callback)
        },
        switchOn: function (speed, callback) {
            return this.show("clip", {}, speed, callback)
        }
    })
})(jQuery);