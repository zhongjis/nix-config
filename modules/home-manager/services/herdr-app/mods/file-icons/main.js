// file-icons: VS Code's Material Icon Theme icons (icons/, matched by icons.js) for the
// filetree mod, which reads them from here and has its own copy of icons.js and the lookup
// (mods cannot import across folders). This mod draws nothing itself.
//
// From github.com/cybertron288/herdr-mods file-icons, itself modified from Herdr's shipped
// `files` mod (https://github.com/herdrdev/herdr-app, Apache-2.0); its file browser is gone.
import { View, div } from "gpui-kit";

export default class FileIcons extends View {
  render() {
    return div().size_full();
  }
}
