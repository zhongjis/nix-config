{...}: {
  vim.augroups = [
    {
      enable = true;
      clear = true;
      name = "KickstartHighlightYank";
    }
    {
      enable = true;
      clear = true;
      name = "JenkinsFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "TerraformFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "HclFileFix";
    }
    {
      enable = true;
      clear = true;
      name = "AutoResize";
    }
    {
      enable = true;
      clear = true;
      name = "AutoSaveBuffer";
    }
  ];

  vim.autocmds = [
    {
      enable = true;
      desc = "Highlight when yanking (copying) text";
      event = ["TextYankPost"];
      group = "KickstartHighlightYank";
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
            vim.highlight.on_yank()
          end
        '';
      };
    }
    {
      enable = true;
      desc = "Set file type for JenkinsFile";
      event = ["BufNewFile" "BufRead"];
      group = "JenkinsFileFix";
      pattern = ["Jenkinsfile*"];
      command = "set filetype=groovy";
    }
    {
      desc = "Set file type for terraform";
      group = "TerraformFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.tf" "*.tfvars"];
      command = "set filetype=terraform";
    }
    {
      desc = "Set file type for hcl";
      group = "HclFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.hcl" ".terraformrc" "terraform.rc"];
      command = "set filetype=hcl";
    }
    {
      desc = "Set file type for terraform state";
      group = "HclFileFix";
      event = ["BufNewFile" "BufRead"];
      pattern = ["*.tfstate" "*.tfstate.backup"];
      command = "set filetype=json";
    }
    {
      desc = "Auto resize panes when window resized";
      group = "AutoResize";
      event = ["VimResized"];
      pattern = ["*"];
      command = "wincmd =";
    }
    {
      desc = "Auto save when leave buffer";
      group = "AutoSaveBuffer";
      event = ["BufLeave" "FocusLost"];
      pattern = ["*"];
      callback = {
        _type = "lua-inline";
        expr = ''
          function()
              -- Get the file type and buffer type of the current buffer
              local filetype = vim.bo.filetype
              local buftype = vim.bo.buftype

              -- If the file type is not 'oil' and the buffer is not a 'nofile' buffer, save the file
              if
                filetype ~= "oil"
                and buftype ~= nil
                and buftype ~= ""
                and buftype ~= "nofile"
                and filetype ~= "harpoon"
                and filetype ~= "trouble"
              then
                vim.cmd("silent wa")
              end
            end
        '';
      };
    }
  ];
}
