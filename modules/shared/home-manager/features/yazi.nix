{...}: {
  programs.yazi = {
    enable = true;

    settings = {
      manager = {
        show_hidden = true;
        sort_dir_first = true;
        layout = [2 3 5];
      };
      input = {
        find_origin = "bottom-left";
        find_offset = [0 2 50 3];
      };
    };
  };
}
