The autoscaler scripts will spawn a (configurable) number of webservers in order to sevice client requests. 
This isn't strictly autoscaling because how many websevers to scale out to is statically defined, so, this toolkit might not be the best solution for use cases that need to service sudden spikes in traffic.

**NOTE** 
If you are deploying in "Development" mode, then remember that auto-scaling or scaling is switched off. 
In production mode scaling is possible and is the full fledged "in the live" solution. 

To configure how many webservers to spawn, please look at 

**${HOME}/config/scalingprofile/profile.cnf**

and adjust the parameters to your needs

**IMPORTANT NOTE** 
#### EVERY TIME YOU UPDATE THE NUMBER OF SERVERS YOU WANT TO AUTOSCALE TO, INSERT AN ADDITIONAL SPACE INTO THE profile.cnf FILE EACH TIME SUCH THAT THE NUMBER OF BYTES IS DIFFERENT BECAUSE IF YOU HAD A VALUE OF 4 AND YOU CHANGE IT TO 6, S3FS WON'T DETECT ANY CHANGE BECAUSE IT DOES IT BY THE NUMBER OF BYTES AND YOU WON'T SEE YOUR CHANGES ON OTHER MACHINES THAT MOUNT YOUR ${HOME}/config DIRECTORY
