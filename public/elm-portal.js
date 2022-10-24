Object.defineProperty(Element.prototype, "___getBoundingClientRect", {
  get() {
    return this.getBoundingClientRect();
  },
});

window.customElements.define(
  "elm-portal",
  class extends HTMLElement {
    // Base custom element stuff
    connectedCallback() {
      this._targetNode = document.createElement("div");
      document
        .getElementById(this.getAttribute("portal-target-id"))
        .appendChild(this._targetNode);
    }

    disconnectedCallback() {
      document
        .getElementById(this.getAttribute("portal-target-id"))
        .removeChild(this._targetNode);
    }

    // Re-implementations of HTMLElement functions
    get childNodes() {
      return this._targetNode.childNodes;
    }

    replaceData(...args) {
      return this._targetNode.replaceData(...args);
    }

    removeChild(...args) {
      return this._targetNode.removeChild(...args);
    }

    insertBefore(...args) {
      return this._targetNode.insertBefore(...args);
    }
    appendChild(...args) {
      // To cooperate with the Elm runtime
      requestAnimationFrame(() => {
        return this._targetNode.appendChild(...args);
      });
    }
  }
);
