{ pkgs, ... }:
{
	programs.oh-my-posh = {
		enable = true;
		enableZshIntegration = true;
		settings = builtins.fromJSON 
		(builtins.unsafeDiscardStringContext (builtins.readFile  "${./powerlevel10k_rainbow.omp.json}"
		)
		);
	};
}
