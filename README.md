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
Open a browser window and type 'http://localhost/dc_mapping?sdg=(1:16)&lang=(E,D,F,I)&output=console'.
sdg" is a number from 1 to 16, which stands for the corresponding SDG
Lang" is either E for English, D for German, F for French or I for Italien.
If you enter only 'http://localhost/dc_mapping`, the default is `sdg=1` and `lang=E`.

## Keyword definition
Keywords are divided into three categories: Priors, Including and Excluding Posteriors. They are combined per prior into one csv. record for each prior. For example, `vulnerable;housh*,group*;mental illness` and reads as follows: Searches for all text passages containing `vulnerable` and either words beginning with `house`(e.g. household) or with `group`(e.g. groups) which do NOT contain mental illness.
### Prior
A prior is always a non-empty string, e.g. `vulnerable`. 

### Including Posteriors
Inclusive posteriors include a string in which the individual terms are separated by a comma and can be written as a regular expression, e.g. `housh*, group*`. In the query logic the comma is replaced by an OR.  If no inclusive posterior is applied, the field must be EMPTY.  

#### Excluding posterior
Excluding posteriors include a string in which the individual terms are also separated by a comma and can be written as a regular expression, e.g. `mental illness, stud*`. In the query logic the comma is replaced by an OR. If no inclusive posterior is applied, the field must be EMPTY.    

### Query result
A query returns 0 to n results. Each found prior-posterior combination returns a record with the following attributes: `handle` is the link to the original complete record; `authors` returns all authors involved in the document; `for_data_analysis` is a summarized text field consisting of title, summary and description"; `doc_id` represents the xth record, related to the imported raw data; `sdgX` defines the corresponding SDG with the Nmmer X(1-16) and returns the found keywords. The entire keyword set is displayed, regardless of the combination in which the posteriors contained in it were made. 
```
{
    "handle": "https://digitalcollection.zhaw.ch/handle/11475/21885",
    "authors": "Ayer, Jean-Marie; Pasquier, Bruno",
    "for_data_analysis": "Crowdfunding and initial coin offerings;  Finanzwirtschaft;  
    Rechtsvergleichung und ausländisches Recht; This chapter argues that blockchain technology 
    enables start-ups and small and medium-sized companies to raise funds from a multitude of 
    investors on a peer-to-peer basis without the involvement of an intermediary. 
    It discusses the phenomenon of initial coin offerings (ICO), illustrates with concrete examples, 
    and reviews the legal framework governing ICOs. Using the potential of distributed ledger technologies, 
    ICOs have emerged as a novel mechanism for financing entrepreneurial ventures. 
    One of the main challenges related to the legal regulation of ICOs is the functional diversity 
    of the tokens issued in crowdfunding campaigns. Tokens can be linked to different types of rights, 
    such as membership rights or property rights. A key aspect regarding the financial market regulations 
    of ICOs is whether the tokens qualify as securities. A fundamental problem for the said qualification lies 
    in the different definitions, depending on the applicable jurisdictions.",
    "doc_id": 285,
    "sdg1": [
      {
        "prior": "financial",
        "posterior": "aid,poverty,poor,north-south divide,development,empowerment",
        "posteriorNOT": "NA"
      }
    ]
  }
```

## Development 

The development environment mounts the frontend code into a caddy container. 

```
docker run --rm -d --network proxynetwork --name devcaddy multimico/caddyhelper:latest
docker exec -it devcaddy /bin/bash
```
