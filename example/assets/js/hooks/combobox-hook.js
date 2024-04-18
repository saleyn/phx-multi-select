const ComboBoxHook = {
  mounted() {
    //this.el.addEventListener('blur', event => {
    //  this.pushEventTo(this.el, 'update', {content: this.el.innerText})
    //})
    //this.handleEvent('cancel', data => {
    //  this.el.innerText = data.content
    //  this.el.blur()
    //})

    this.input   = document.querySelectorAll(`[id^=${this.el.id}]>div>input`)[0]
    this.overlay = document.getElementById(this.el.id + '-overlay')
    this.overlay.style.fontFamily = window.getComputedStyle(this.input, null ).getPropertyValue('font-family');
    this.overlay.style.fontSize = window.getComputedStyle(this.input, null ).getPropertyValue('font-size');

    this.input.addEventListener('keyup', event => {
      const len = this.input.value.length
      this.selectText(this.input, len)
      //this.pushEventTo(this.el, 'key', {content: this.el.innerText})
    })
  },

  // Select the count of characters in the beginning of the field's input
  selectText(field, count) {
    const start = 0
    if( field.createTextRange ) {
      var selRange = field.createTextRange();
      selRange.collapse(true);
      selRange.moveStart('character', start);
      selRange.moveEnd('character', count);
      selRange.select();
      field.focus();
    } else if( field.setSelectionRange ) {
      field.focus();
      field.setSelectionRange(0, count, 'forward');
    } else if( typeof field.selectionStart != 'undefined' ) {
      field.selectionStart = start;
      field.selectionEnd = count;
      field.focus();
    }
  }
}

export default ComboBoxHook