{ pkgs, ... }: 
{
	
	nixpkgs.config.android_sdk.accept_license = true;
	environment.systemPackages = with pkgs; [
		# android-studio
		android-studio
		# amdgpu usage
		amdgpu_top
		# protobuf
		protobuf
	];
}
