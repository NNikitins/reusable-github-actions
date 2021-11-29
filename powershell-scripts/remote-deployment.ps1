param (
	$machine_name, 
	$user_password,
	$username,
	$docker_username,
	$docker_password,
	
	[string] $docker_branch, 

	[string] $docker_container,
  
	[string] $docker_port,
	
	[string] $docker_registry,
	
	[string]$public_http
)

# First of all we need to create PSCredential object, that will be used in session creation process

# 1. Save our user's password in a variable
$passwd = convertto-securestring -AsPlainText -Force -String $user_password
# 2. Create credential variable (username should be provided with domain, like corp\nikita.nikitin)
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "${username}", $passwd
# 3. Create session variable
$session = new-pssession -computername $machine_name -credential $cred

# 4. Connect to machine, won't be used, cause Invoke-Command is used
#Enter-PSSession $session

Try {Invoke-Command -Session $session -ScriptBlock {docker login -u "$Using:docker_username" -p "$Using:docker_password"} } Catch {Write-Host "Docker login error"}

Try {Invoke-Command -Session $session -ScriptBlock { docker pull "${Using:docker_username}/${Using:docker_container}:${Using:docker_branch}"}} Catch { Write-Host "An error occured while pulling the docker image"}
Try { Invoke-Command -Session $session -ScriptBlock { $imageToStop = "${Using:docker_username}/${Using:docker_container}:${Using:docker_branch}";$activeRequiredImages = docker ps | Select-String $imageToStop;if (!$activeRequiredImages){Write-Host "the image with that name is not found!";} else { docker stop $imageToStop;} }} Catch {Write-Host "An error occurred while deleting local docker image";}
Invoke-Command -Session $session -ScriptBlock {  sleep 3; }
Try{Invoke-Command -Session $session -ScriptBlock { docker run --name  $Using:docker_container -e AbleFormsAuthPublicOrigin=${Using:public_http} -it -d -p ${Using:docker_port}:80 "${Using:docker_username}/${Using:docker_container}:${Using:docker_branch}"; }} Catch { Write-Host "An error occurred while running docker image on the Windows 2016 machine"; }
