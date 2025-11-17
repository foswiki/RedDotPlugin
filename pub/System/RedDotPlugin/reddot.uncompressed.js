/*
 * jQuery.RedDot plugin
 *
 * Copyright (c) 2010-2025 Michael Daum http://michaeldaumconsulting.com
 *
 * Licensed under the GPL license http://www.gnu.org/licenses/gpl.html
 *
 */
"use strict";
(function($) {

  /***************************************************************************
   * class definition
   */
  function RedDot(elem, opts) {
    var self = this;

    self.elem = $(elem);
    self.anchor = self.elem.children("a:first");
    self.opts = $.extend({}, opts, self.elem.data());
    self.init();
  }

  /***************************************************************************
   * init redDot instance
   */
  RedDot.prototype.init = function() {
    var self = this;

    if (typeof(self.opts.parent) === 'undefined') {
      self.parentElem = self.elem.parent();
    } else {
      self.parentElem = self.elem.parents(self.opts.parent).first();
    }

    self.parentElem.hoverIntent({
      over: function() {
        self.anchor.fadeIn(500, function() {
          self.anchor.css({opacity: 1.0});
        });
      },
      out: function() {
        self.anchor.stop();
        self.anchor.css({display:'none', opacity: 1.0});  
      }
    });
  };

  /***************************************************************************
   * make it a jQuery plugin
   */
  $.fn.redDot = function(opts) {
    return this.each(function() {
      if (!$.data(this, "redDot")) {
        $.data(this, "redDot", new RedDot(this, opts));
      }
    });
  };

  /***************************************************************************
   * enable declarative widget instanziation
   */
  $(function() {
    $(".redDotAnimated").livequery(function() {
      $(this).redDot();
    });
  });

})(jQuery);
