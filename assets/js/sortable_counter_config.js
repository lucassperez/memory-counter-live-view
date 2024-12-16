import Sortable from "../vendor/sortable"

SortableCounters = {
  mounted() {
    Sortable.create(this.el, {
      animation: 150,
      swapThreshold: 1,
      direction: 'vertical',
      ghostClass: "sortable-ghost",
      onEnd: (event) => {
        this.pushEvent("reorder_counters", {
          oldIndex: event.oldIndex,
          newIndex: event.newIndex,
        });
      },
    });
  }
};

export default SortableCounters;
