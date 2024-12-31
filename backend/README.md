# Upload to Azure Container Registry
(When building the image in MacOS Silicon, please make sure the platform for docker is not ARM)
https://chatgpt.com/c/67725162-d2cc-8010-8a79-aeefccb7902b
* az acr login --name yusakuno1acr --resource-group yusakuno1_ai_rg
* docker tag ewo-voiceassistant yusakuno1acr.azurecr.io/ewo-voiceassistant:latest
* docker push yusakuno1acr.azurecr.io/ewo-voiceassistant:latest

# Deploy the API app from Azure Container Registry
* (Not 100% sure) May need to add controbutor role
* (Not 100% sure) May need to set "Managed Identity" from Webapp "Deployment Center" -> "Settings"
* az group create --name yusakuno1_api_app_rg --location eastus2
* az appservice plan create --name yusakuno1AppServicePlan --resource-group yusakuno1_api_app_rg --sku F1 --is-linux
* az webapp create --resource-group yusakuno1_api_app_rg --plan yusakuno1AppServicePlan --name yusakuno1AppServicePlan --deployment-container-image-name yusakuno1acr.azurecr.io/ewo-voiceassistant:latest
* Enable logging:
  * az webapp log config --name yusakuno1AppServicePlan --resource-group yusakuno1_api_app_rg --docker-container-logging filesystem
  * az webapp log tail --name yusakuno1AppServicePlan --resource-group yusakuno1_api_app_rg
