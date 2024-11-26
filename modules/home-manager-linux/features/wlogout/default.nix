{config, ...}: {
  xdg.configFile."wlogout/icons".source = ./icons;

  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "logout";
        action = "loginctl kill-session $XDG_SESSION_ID";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
    ];
    style = with config.lib.stylix.colors;
    /*
    css
    */
      ''
        /* Importing pywal colors */

        @define-color foreground #F0D5DB;
        @define-color background rgba(11,10,14,0.25);
        @define-color cursor #F0D5DB;

        @define-color color0 #0B0A0E;
        @define-color color1 #30283A;
        @define-color color2 #5A455C;
        @define-color color3 #634454;
        @define-color color4 #5D475E;
        @define-color color5 #905C6A;
        @define-color color6 #9E6571;
        @define-color color7 #E1BAC3;
        @define-color color8 #9D8288;
        @define-color color9 #40354D;
        @define-color color10 #785C7B;
        @define-color color11 #845B6F;
        @define-color color12 #7C5F7E;
        @define-color color13 #BF7B8D;
        @define-color color14 #D38697;
        @define-color color15 #E1BAC3;

        window {
          font-family: Fira Code Medium;
          font-size: 16pt;
          color: #cdd6f4; /* text */
          background-color: rgba(30, 30, 46, 0.6);
        }

        button {
          background-repeat: no-repeat;
          background-position: center;
          background-size: 20%;
          background-color: rgba(200, 220, 255, 0);
          border-radius: 50px; /* Increased border radius for a more rounded look */
        }

        button:focus {
          background-size: 25%;
          border: 0px;
        }

        button:hover {
          background-color: rgb(145, 215, 227);
          color: #1e1e2e;
          background-size: 70%;
          margin: 5px;
          border-radius: 50px;
        }

        /* Adjust the size of the icon or content inside the button */
        button span {
          font-size: 1.2em; /* Increase the font size */
        }

        #lock {
          background-image: image(url("./icons/lock.png"));
        }
        #lock:hover {
          background-image: image(url("./icons/lock-hover.png"));
        }

        #logout {
          background-image: image(url("./icons/logout.png"));
        }
        #logout:hover {
          background-image: image(url("./icons/logout-hover.png"));
        }

        #suspend {
          background-image: image(url("./icons/sleep.png"));
        }
        #suspend:hover {
          background-image: image(url("./icons/sleep-hover.png"));
        }

        #shutdown {
          background-image: image(url("./icons/power.png"));
        }
        #shutdown:hover {
          background-image: image(url("./icons/power-hover.png"));
        }

        #reboot {
          background-image: image(url("./icons/restart.png"));
        }
        #reboot:hover {
          background-image: image(url("./icons/restart-hover.png"));
        }

        #hibernate {
          background-image: image(url("./icons/hibernate.png"));
        }
        #hibernate:hover {
          background-image: image(url("./icons/hibernate-hover.png"));
        }
      '';
  };
}
