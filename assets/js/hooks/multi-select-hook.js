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

      if (items.length > 1 && wrapped ^ this.wasWrapped) {
        this.wasWrapped = wrapped
        this.pushEventTo(this.el.dataset.target, "wrapped",
          { count: eleCount, value: wrapped })
      }
    });
    resizeObserver.observe(this.el)
  },
}

export default MultiSelectHook