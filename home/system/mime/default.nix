# Mime allows us to configure the default applications for each file type
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/markdown" = "nvim-kitty.desktop";
      "text/plain" = "nvim-kitty.desktop";
      "text/x-shellscript" = "nvim-kitty.desktop";
      "text/x-python" = "nvim-kitty.desktop";
      "text/x-go" = "nvim-kitty.desktop";
      "text/css" = "nvim-kitty.desktop";
      "text/javascript" = "nvim-kitty.desktop";
      "text/x-c" = "nvim-kitty.desktop";
      "text/x-c++" = "nvim-kitty.desktop";
      "text/x-java" = "nvim-kitty.desktop";
      "text/x-rust" = "nvim-kitty.desktop";
      "text/x-yaml" = "nvim-kitty.desktop";
      "text/x-toml" = "nvim-kitty.desktop";
      "text/x-dockerfile" = "nvim-kitty.desktop";
      "text/x-xml" = "nvim-kitty.desktop";
      "text/x-php" = "nvim-kitty.desktop";
      # zathura 的 mupdf 插件支持 png/jpeg/svg/bmp/tiff，但不支持 webp/gif
      "image/jpeg" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/jpg" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/png" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/svg+xml" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/bmp" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/tiff" = "org.pwmt.zathura-pdf-mupdf.desktop";
      # webp/gif：zathura 不支持，走浏览器
      "image/webp" = "zen-beta.desktop";
      "image/gif" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      # 注意：实际 .desktop 文件名是 org.pwmt.zathura-pdf-mupdf.desktop，
      # 写短名 zathura.desktop 解析不到会被跳过，PDF 会回退到 Chrome
      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/x-directory" = "org.gnome.Nautilus.desktop";
    };
  };

  # nvim 是终端应用（Terminal=true），niri 下 xdg-open 无法启动它。
  # 声明一个"nvim 跑在 kitty 里"的包装 .desktop，text/* 才能正常打开。
  xdg.desktopEntries."nvim-kitty" = {
    name = "Nvim (kitty)";
    exec = "kitty -e nvim %F";
    terminal = false;
    type = "Application";
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" ];
  };
}
