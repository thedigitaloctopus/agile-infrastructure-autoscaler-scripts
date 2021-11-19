The autoscaler scripts will spawn a (configurable) number of webservers in order to sevice client requests. 
This isn't strictly autoscaling because how many websevers to scale out to is statically defined, so, this toolkit might not be the best solution for use cases that need to service sudden spikes in traffic.

**NOTE** 
If you are deploying in "Development" mode, then remember that auto-scaling or scaling is switched off. 
In production mode scaling is possible and is the full fledged "in the live" solution. 


