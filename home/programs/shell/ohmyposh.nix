{ pkgs, ... }:
{
	programs.oh-my-posh = {
		enable = true;
		enableZshIntegration = true;
		settings = builtins.fromJSON 
		(builtins.unsafeDiscardStringContext (builtins.readFile  "${./the-unnamed.omp.json}"
		)
		);
	};
}
