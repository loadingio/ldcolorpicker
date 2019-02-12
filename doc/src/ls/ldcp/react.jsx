if(typeof(React)!=="undefined" && React.DOM) {
  class LDColorPicker extends React.Component {
    constructor(props) {
      super(props);
    }
    render() {
      return (
        <div className="ldColorPicker"></div>
      );
    }
    componentDidMount() {
      var root = ReactDOM.findDOMNode(this);
      var ldcp = new ldColorPicker(null, (this.props || {}), root);
    }
    componentWillUnmount() {}
  }

  window.LDColorPicker = LDColorPicker;
}
