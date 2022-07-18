# Build a docker image - push it to github packages - pull it to local

The purpose of this repo is to implement a simple docker container using the Github Packages manager.
A very good tutorial can be found at: `https://www.youtube.com/watch?v=qoMg86QA5P4`


## Creating a new token
- Navigate to `github.com/setting/tokens`and click on `Generate new token`

## Adding the new token to the ENV variables:
- Open terminal and enter

```
export CR_PAT | docker login ghcr.io -u bajk --password-stdin
```

## Creating a docker image
- navigate to the local Git folder containing all docker relevant files and copy the path to this folder.
- In Terminal switch to this folder.
- In Terminal enter either a) for single platform use or b) for multiplatform use.
```
a) docker build -t ghcr.io/sustainability-zhaw/sdg-validation:latest` .
b) docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sustainability-zhaw/sdg-validation:latest --push .
```

- Check if the new image is visible in docker desktop

## Testing
Test the service using the following command. 
```
docker run -itd -p 80:80 --entrypoint /bin/sh ghcr.io/sustainability-zhaw/sdg-validation:latest
curl localhost/hello
```

## Pushing the package to Git
Push the docker Image to git
`docker push ghcr.io/sustainability-zhaw/hello-api-temp:latest`

## Assigning a package to a repository
- Select the Namespace path `sustainability-zhaw`and select `Packages`
- Select the package names `hello-package` and click on `Package settings` in the right sided vertical bar.
- Select the green button `Connect Repository` and address the package to a repository of your choice. In our case it is the repository `hello-package`.
- As a suggestion check the box for `Inherit access from source repository (recommended)`

## Checking the visibility of the package within the repository
- In the right sided vertical bar you should see the Package `hello-package`. 
Click on the name to opern a new window showing further package details, 
like the docker image pull command
```
docker pull ghcr.io/sustainability-zhaw/hello-package:latest
```
