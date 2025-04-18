{ pkgs, ... }: 
{
	
	environment.systemPackages = with pkgs; [
		# android-studio
		android-studio
		# amdgpu usage
		amdgpu_top
		# protobuf
		protobuf
	];
}
