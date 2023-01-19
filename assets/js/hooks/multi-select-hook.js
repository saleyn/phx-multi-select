const MultiSelectHook = {
  wasWrapped: false,
  mounted() {
    const resizeObserver = new ResizeObserver((observed) => {
      if (observed == [])  return
      const items    = observed[0].target.children
      let   prevItem = {}
      let   currItem = {}
      let   wrapped  = false
      let   eleCount = 0

      for (var i = 0; i < items.length; ++i, ++eleCount) {
        currItem = items[i].getBoundingClientRect();
        if (prevItem && prevItem.top < currItem.top) {
          wrapped = true
          break
        }
        prevItem = currItem;
      }

      if (items.length > 1 && (wrapped ^ this.wasWrapped) && this.el.dataset.wrap !== 'true') {
        this.wasWrapped = wrapped
        this.pushEventTo(this.el.dataset.target, 'wrapped', { count: eleCount, value: wrapped })
      }
    });
    resizeObserver.observe(this.el)
  },
}

// >>> START Global Event Listeners
window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
window.addEventListener("js:set",  e => e.target[e.detail.key] = e.detail.value)
window.addEventListener("js:set_input_value", e => e.target.value = e.detail)
window.addEventListener("js:ignore_empty_input", e => {
  let t = e.target
  if (t.value == "") t.name = t.id; else t.removeAttribute('name');
})

// <<< END Global Event Listeners

export default MultiSelectHook