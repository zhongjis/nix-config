{pkgs, ...}: {
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
      strategies = {
        "lazy" = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 15;
            }
            {
              temp = 50;
              speed = 25;
            }
            {
              temp = 65;
              speed = 35;
            }
            {
              temp = 75;
              speed = 55;
            }
            {
              temp = 85;
              speed = 85;
            }
            {
              temp = 95;
              speed = 100;
            }
          ];
        };
      };
    };
  };
}
