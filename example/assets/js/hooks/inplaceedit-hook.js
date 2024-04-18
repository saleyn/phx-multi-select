const InPlaceEdit = {
  mounted() {
    this.el.addEventListener('blur', event => {
      this.pushEventTo(this.el, 'update', {content: this.el.innerText})
    })

    this.el.addEventListener('keyup', event => {
      console.log(event)
      this.pushEventTo(this.el, 'key', {content: this.el.innerText})
    })

    this.handleEvent('cancel', data => {
      this.el.innerText = data.content
      this.el.blur()
    })
  }
}

export default InPlaceEdit