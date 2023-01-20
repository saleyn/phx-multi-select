import JS from "../../../deps/phoenix_live_view/assets/js/phoenix_live_view/js"

const MultiSelectHook = {
  wasWrapped: false,
  oldFilterVal: "",
  id: null,

  mounted() {
    this.id = this.el.id.replace(/-tags$/, '')

    // Client-side value filtering with filtering value sent to server
    this.filterElement().onkeyup = () => this.applyFilter(this, true)

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

  updated() { this.applyFilter(this, false) },

  filterElement() { return document.getElementById(`${this.id}-filter`) },

  applyFilter(obj, mounted) {
    const filterEle = obj.filterElement()
    console.log(`Mounted: ${mounted}, filter: ${filterEle.value}`)
    const optsItems = document.querySelectorAll('[id^=multi-opts]>div>label>input')

    if (mounted && filterEle.value == "" && obj.oldFilterVal != "")
      filterEle.value = obj.oldFilterVal
    else if (filterEle.value === obj.oldFilterVal)
      return
    obj.oldFilterVal = filterEle.value
    const needle = new RegExp(filterEle.value, 'i')
    for (let opt of optsItems) {
      let   label = opt.parentElement
      const show  = filterEle.value === '' ||
                    needle.test(label.textContent)
      if (show)
        label.parentElement.removeAttribute('hidden')
      else
        label.parentElement.setAttribute('hidden', '')
    }

    obj.pushEventTo(obj.el.dataset.target, 'search', { filter: filterEle.value })
  }
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