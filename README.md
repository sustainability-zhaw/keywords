# sustainability-keyword-mapping validator
Support-Tool for the ZHAW Sustainability keyword mapping

## Purpose

The sustainability keywords mapping tool provides a web browser interface for mapping ZHAW sustainability keywords to the digital collection.

The mapping process runs in a Docker container and is deployed locally in a web browser on port `80`.

The mapping process is embedded into a docker container that is designed to be hosted *behind* a reverse proxy server. That proxy server maintains authentication and SSL-Termination. Neverthless in the current version the docker container will run on a user local docker installation. Therefore several installation steps are necessary and are discussed further down in this document.

No user interface is implemented. Instead, all setup commands are executed via the command line in a terminal program.

## Development environment

Only experienced developers should use these two commend, since they rebuild the whole container und provide it on the users local machoine. 
In order to run the sdg mapping service there is NO need to change anything on the folder structure or on the code!
```
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sustainability-zhaw/sdg-validation:latest --push .
docker pull ghcr.io/sustainability-zhaw/sdg-validation:latest
```

## Windows Setup

### Docker installation, if not yet installed
Go to the docker install webpage and download **Docker Desktop for Window** by clicking on it
``` 
docs.docker.com/desktop/install/windows-install
```
Double-click the downloaded file `Docker Desktop Installer.exe` and `Run`.
Agree to use WLS 2 instead of Hyper-V and `Add shortcut to desktop` when prompted.
After successful installation, the laptop must be restarted. Confirm the prompt.
After rebooting you should see Docker Desktop Icon.
You might see several Windiows Error prompts. Follow them and accept the proposed actions.

## Starting the SDG mapping service
The SDG mapping service is started with the following command. The --rm parameter tells Docker that the service, which is visible in the Docker desktop as a container, will be removed after exposing the mapping results and must be restarted for another mapping run.
```
docker run --rm -d -p 80:8000 --name sdgmapping ghcr.io/sustainability-zhaw/sdg-validation:latest
```
The second way to start the SDG mapping service is from Docker Desktop. Select `Images` in the left vertical bar of Docker Desktop and select the row with the image you want to create a container from. On the right side of the selected row, you will see a blue button named `Run`. Click on it and expand the `Optional settings`. Enter a suitable container name and type `80` as `host port`. To verify that the container is running, switch from `Images` to `Containers`. You should see a container with the chosen name running on port 80 and specifying a time in the `Started` field.

## Run the SDG mapping service
Open a Browser Window and enter http://localhost/dc_mapping?sdg=1&list_with_posteriors=TRUE&output=console

## Development 

The development environment mounts the frontend code into a caddy container. 

```
docker run --rm -d --network proxynetwork --name devcaddy multimico/caddyhelper:latest
docker exec -it devcaddy /bin/ash
```
## Keyword definition
There are four ways in which priors and postiors can be defined.
### Prior
A prior is always a non-empty string, e.g. `"vulnerable"`. 

### Posteriors
These are the ways to define posteriors.

#### No posterior
Do not leave the string empty. Define the posterior as "NA" (not available), e.g. `"vulnerable, NA"`. 

#### A matching posterior
This posterior must be in the same sentence as the prior to get a match, e.g. `"vulnerable, house*"` . In this example, `house*` represents a regular expression, i.e., any expression starting with `house`, such as `house` or `houseboat` will be found,  

#### An EXCLUSIVE Posterior
This type of posterior means that once the corresponding prior is found in a sentence, the excluding posterior must not be found in the same sentence, ` vulnerable, ^house*"`.. 


"^housh*, disadvantage, ^mental illness"
