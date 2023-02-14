// Multi Select Hook
// =================
// Phoenix LiveView hook for the multi_select live component

const MultiSelectHook = {
  wasWrapped: false,
  oldFilterVal: "",
  id:     null,
  input:  null,
  iconS1: null,
  iconS2: null,

  mounted() {
    this.id      = this.el.id.replace(/-tags$/, '')
    this.filter  = document.getElementById(`${this.id}-filter`)
    this.inputS1 = document.getElementsByName(`${this.id}-flt-check`)[0]
    this.iconS1  = document.getElementById(`${this.id}-flt-check`)
    this.iconS2  = document.getElementById(`${this.id}-flt-clear`)

    // Client-side value filtering with filtering value sent to server
    this.filter.onkeyup = (evt) => this.applyFilter(this, true)

    this.filterClearIcon().onclick = (obj) => {
      this.filter.value = ''
      this.applyFilter(this, false)
      if (this.el.dataset.filterside == 'server')
        this.pushEventTo(this.el.dataset.target, 'filter', {icon: 'clear'})
    }

    this.filterCheckIcon().onclick = (obj) =>
      this.updateCheckIconState(this.inputS1.value !== 'true')

    this.updateCheckIconState(false)

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

  updated() {
    this.applyFilter(this, false)
    this.updateCheckIconState(this.inputS1.value === 'true')
  },

  updateCheckIconState(checked) {
    const ds           = this.iconS1.dataset
    let   titles       = ds.titles && ds.titles.trim().split("|") || ["",""]
    this.iconS1.value  = checked ? 'on' : 'off'
    this.inputS1.value = `${checked}`
    this.iconS1.querySelector('title').innerHTML = titles[checked ? 1 : 0]

    const hasChecks = this.applyFilter(this, false)

    if (ds.colors) {
      let colors = ds.colors.trim().split("|")
      if (hasChecks) {
        colors[checked ? 0 : 1].split(" ").filter(x => x != "").forEach(c => this.iconS1.classList.remove(c));
        colors[checked ? 1 : 0].split(" ").filter(x => x != "").forEach(c => this.iconS1.classList.add(c));
      } else {
        // disable
        colors[0].split(" ").filter(x => x != "").forEach(c => this.iconS1.classList.remove(c))
        colors[1].split(" ").filter(x => x != "").forEach(c => this.iconS1.classList.remove(c))
      }
    }

    if (ds.filterside == 'server')
      this.pushEventTo(ds.target, 'filter', {icon: 'check', checked: checked})
  },

  filterClearIcon() { return document.getElementById(`${this.id}-flt-clear`) },
  filterCheckIcon() { return document.getElementById(`${this.id}-flt-check`) },

  applyFilter(obj, mounted) {
    const filterVal     = this.filter.value
    const filterChecked = this.inputS1.value === 'true'
    const optsItems = document.querySelectorAll(`[id^=${this.id}-opts]>div>label>input`)
    let   hasChecks = false
    for (let opt of optsItems)
      if (opt.checked) {
        hasChecks = true
        break
      }

    let rex = new RegExp();
    try { rex = new RegExp(filterVal, 'i'); } catch (_) { }

    for (let opt of optsItems) {
      let   label = opt.parentElement
      const show  = ((filterVal === '' || rex.test(label.textContent)) && !filterChecked)
                  || (filterChecked && opt.checked)
      if (show)
        label.parentElement.removeAttribute('hidden')
      else
        label.parentElement.setAttribute('hidden', '')
    }

    if (obj.el.dataset.filterside == 'server')
      obj.pushEventTo(obj.el.dataset.target, 'search', { filter: filterVal })

    return hasChecks
  }
}

export default MultiSelectHook
