import React, { PureComponent } from "react";

import { WorkspaceLoader } from "~/ligo-components/ligo-project";
import { connect } from "~/base-components/redux";

class ProjectWithProps extends PureComponent {
  async componentDidMount() {
    this.props.cacheLifecycles.didRecover(() => {
      window.dispatchEvent(new Event("resize"));
    });
  }

  render() {
    const { projects, uiState, match } = this.props;
    if (!match?.params) {
      return null;
    }
    const { username, project } = match?.params;
    const selected = projects.get("selected")?.toJS() || {};

    let type;
    let projectRoot;
    if (username === "local") {
      type = "Local";
      projectRoot = selected.path;
    } else {
      type = "Remote";
      projectRoot = selected.id ? `${username}/${project}` : undefined;
    }

    return (
      <WorkspaceLoader
        theme="ligoide"
        projectRoot={projectRoot}
        type={type}
        signer={uiState.get("signer")}
      />
    );
  }
}

export default connect(["uiState", "projects"])(ProjectWithProps);
