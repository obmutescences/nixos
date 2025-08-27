# My shell configuration
{ pkgs, lib, config, ... }:
let fetch = config.var.theme.fetch; # neofetch, nerdfetch, pfetch
in {

  home.packages = with pkgs; [ bat ripgrep tldr sesh ];

  home.sessionPath = [ 
	"$HOME/go/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = false;

    initContent = lib.mkBefore ''
      bindkey -e
      ${if fetch == "neofetch" then
        pkgs.neofetch + "/bin/neofetch"
      else
        ""}

      function sesh-sessions() {
        session=$(sesh list -t -c | fzf --height 70% --reverse)
        [[ -z "$session" ]] && return
        sesh connect $session
      }

      zle     -N             sesh-sessions
      bindkey -M emacs '\es' sesh-sessions
      bindkey -M vicmd '\es' sesh-sessions
      bindkey -M viins '\es' sesh-sessions
	  # 在自动补全时忽略大小写
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
	  # 读取密钥环境变量
	  if [ -f "$HOME/.env.secret" ]; then
		 source "$HOME/.env.secret"
	  fi
	  export PATH="$HOME/.cargo/bin:$PATH"
	  export PATH="$HOME/.npm/bin:$PATH"

	  # ---rust 项目开发所需,后续不用可删除
	  export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
	  export BINDGEN_EXTRA_CLANG_ARGS="-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.versions.major (pkgs.lib.getVersion pkgs.clang)}/include"
    '';

    history = {
      ignoreDups = true;
      save = 10000;
      size = 10000;
    };

    profileExtra = lib.optionalString (config.home.sessionPath != [ ]) ''
      export PATH="$PATH''${PATH:+:}${
        lib.concatStringsSep ":" config.home.sessionPath
      }"
    '';

    #NOTE- for btop to show gpu usage 
    #may want to check the driver version with:
    #nix path-info -r /run/current-system | grep nvidia-x11
    #and 
    #nix search nixpkgs nvidia_x11
    sessionVariables = {
      LD_LIBRARY_PATH = lib.concatStringsSep ":" [
        "${pkgs.linuxPackages_latest.nvidia_x11_beta}/lib" # change the package name according to nix search result
        "$LD_LIBRARY_PATH"
      ];
    };

    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      v = "nvim";
      c = "clear";
      cd = "z";
      ls = "eza --icons=always --no-quotes";
      tree = "eza --icons=always --tree --no-quotes";
      sl = "ls";
      open = "${pkgs.xdg-utils}/bin/xdg-open";
      icat = "${pkgs.kitty}/bin/kitty +kitten icat";
      ssh = "kitty +kitten ssh";
	  du = "dust";
	  ping = "gping";
	  cat = "bat --theme=dracula";

      # git
      # g = "lazygit";
      ga = "git add";
      gc = "git commit";
      gcu = "git add . && git commit -m 'Update'";
      gp = "git push";
      gpl = "git pull";
      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      gcb = "git checkout -b";
      gbr = "git branch";
      grs = "git reset HEAD~1";
      grh = "git reset --hard HEAD~1";

      gaa = "git add .";
      gcm = "git commit -m";
    };
  };
}
