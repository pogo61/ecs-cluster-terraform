# ecs-cluster-terraform
terraform and python lambda that creates and allows for autoscaling of an ECS cluster

This repo is under refactor, but is also used as an example of how to use the Backstage IaC support plugin https://github.com/pogo61/Backstage-IaC-Plugin

Under the 'deployment' folder you'll notice a number of child folders:
* dev
* Modules contain the Terraform modules used by the other environment's terraform scripts

The **dev** folder has a file called 'catalog-info.yaml'.

This is a file that defines the Environment entity created in https://github.com/pogo61/Backstage-IaC-Plugin.
As well as the Group and Domain entities it uses (normal types in Backstage). It also defines a System Component that points to the pipeline used to build the terraform IaC.

The **Modules** folder has a 'ecs-cluster' folder which contained the ECS Cluster module referenced above. Because this uses other modules like asg, cloudwatch, etc,
there is another file called 'catalog-info.yaml'.
This file defines the root ecs-cluster ResourceComponent, and the child asg, etc ResourceComponents it uses.

Lastly, in the root folder of this project is a template.yaml file.
This defines a re-usable 'form' in backstage that takes the parameters need in the pipeline, defined in the Dev's catalog-info.yaml (above)
and fires off the pipeline.

So, to make this all work in backstage:
1. the dev folder catalog-info.yaml's url is given to backstage, and it imports the Environment, pipeline, and other  entities defined
2. the modules folder catalog-info.yaml's url is given to backstage, and it imports all the ResourceComponent entities defined 
3. the root template.yaml file's url is given to backstage,imports and makes available a template in the page off the Home-> create menu item.

For clarity's sake, a catalog-info.yaml file would be needed in every folder (test, Production) that the ECS cluster was deployed into, with the /modules/ecs-cluster catalog-info.yaml modified to include those environments, for this to be shown in Backstage.

Once you have the IaC plugin set up in your Backstage, import these url's and check out the result.

There is a more detailed description on what does what and how to use the plugin with this example IaC repo at
https://medium.com/@paulpogonoski/backstage-iac-support-392f34ea118e
