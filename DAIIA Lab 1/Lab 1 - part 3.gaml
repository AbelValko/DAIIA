/**
* Name: Lab 1 - basic
* Based on the internal empty template. 
* Author: Abel 
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
	int stepCounterVariable <- 0 update: stepCounterVariable+1;
	
	int numberOfGuests <- 3;
	int numberOfSecurity <- 4;
	int numberOfStoresFood <- 2;
	int numberOfStoresDrink <- 2;
	int numberOfInfoCenters <- 2;
	int securityCounter <- 0;
	
	int infoDistanceThreshold <- 0;
	int consumeDistanceThreshold <- 1;
	
	list foodLocations <- nil;
	list drinkLocations <- nil;
	
	init {
		create Guest number:numberOfGuests;
		create Store number:numberOfStoresFood with: (type:"food");
		create Store number:numberOfStoresDrink with: (type:"drink");
		create InformationCenter number:numberOfInfoCenters;
		create Security number:numberOfSecurity;

		loop counter from: 1 to: numberOfGuests {
        	Guest my_agent <- Guest[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
        
        loop counter from: 1 to: numberOfSecurity {
        	Security my_agent <- Security[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
        
        loop counter from: 1 to: numberOfInfoCenters {
        	InformationCenter my_agent <- InformationCenter[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
	}	
}

species Guest skills: [moving]{
	bool hungry <- false;
	bool thirsty <- false;
	bool good <- flip(0.5);
	point foodObjective <- nil;
	point drinkObjective <- nil;
	point rememberfood <- nil;
	point rememberdrink <- nil;
	point infoObjective <- nil;
	string personName <- "Undefined";
	bool alive <- true;
	
	aspect base {
		rgb agentcolor <- rgb("grey");
		if good{
			if (hungry and thirsty) {
				agentcolor <- rgb("purple");
			} else if (hungry) {
				agentcolor <- rgb("red");
			} else if (thirsty) {
				agentcolor <- rgb("blue");
			} else {
				agentcolor <- rgb("green");
			}
		}
		else{
			if (hungry and thirsty) {
				agentcolor <- rgb("pink");
			} else if (hungry) {
				agentcolor <- rgb("maroon");
			} else if (thirsty) {
				agentcolor <- rgb("yellow");
			} else {
				agentcolor <- rgb("black");
			}
		}
		
		
		draw circle(1) color:agentcolor;
	}
	
	reflex updateHungerAndThirst {
		if (!hungry) {
			hungry <- flip(0.01);
			if hungry {
				write personName+":I'm hungry";
				do updateInfoObjective;	
			}
		}
		if (!thirsty){
			thirsty <- flip(0.02);
			if thirsty {
				write personName+":I'm thirsty";
				do updateInfoObjective;
			}
		}
	}
	
	reflex agent_die when: !empty(Security at_distance consumeDistanceThreshold) and !good{
		list copsNearMe <- Security at_distance consumeDistanceThreshold;
		if !(copsNearMe[0].badGuyName = nil){
			numberOfGuests <- numberOfGuests -1;
			write personName+" died";
			copsNearMe[0].infoObjective <-nil;
			copsNearMe[0].badGuyName <- nil;
			copsNearMe[0].target <- nil;
			write copsNearMe[0].personName + " values reset";
			alive <- false;
			do die;
			
			
		}
		
	}
	
	reflex move{
		if (drinkObjective != nil) {
			do goto target:drinkObjective;
			write personName+":moving to drink";
		} else if (foodObjective != nil) {
			do goto target:foodObjective;
			write personName+":moving to food";
		} else if (hungry or thirsty){
			bool y_n <- (flip(0.3) or (rememberfood = nil or rememberdrink = nil) );
			if y_n{
				rememberfood <- nil;
				rememberdrink <- nil;
				do goto target:infoObjective;
				write personName+":moving to info";
			}
			else{
				write personName+":Going to previous store";
				if hungry{
					foodObjective <- rememberfood;
				}
				if thirsty{
					drinkObjective <- rememberdrink;
				}
				
			}
				
		} else {
			do wander;
			write personName+":wandering";
		}
	}
		
	reflex checkForInfo when: ((hungry or thirsty) and ((drinkObjective = nil)  or (foodObjective = nil))) and !empty(InformationCenter at_distance infoDistanceThreshold) {
		write personName+":Asking for directions!";
		list infoCentersNearMe <- InformationCenter at_distance infoDistanceThreshold;
		bool y_n <- (flip(0.3) or (rememberfood = nil or rememberdrink = nil) );
		if y_n{
			write personName+":Going to info center";
			ask infoCentersNearMe[0]{
			if myself.hungry{
				myself.foodObjective <- self.recommendedFood;
				myself.rememberfood <- myself.foodObjective;
				write myself.personName+":New food objective found: " + myself.foodObjective;
			}
			if myself.thirsty{
				myself.drinkObjective <- self.recommendedDrink;
				myself.rememberdrink <- myself.drinkObjective;
				write myself.personName+":New drink objective found: " + myself.drinkObjective;
			}
		}
		}
		else{
			
		}
		
	}
	
	reflex consumeStuff when: !empty(Store at_distance consumeDistanceThreshold){
		list storesNearMe <- Store at_distance consumeDistanceThreshold;
		if thirsty {
			if storesNearMe[0].type = "drink"{
				thirsty <- false;
				drinkObjective <- nil;
				write personName+":drinking";
			}
		}
		if hungry {
			if storesNearMe[0].type = "food"{
				hungry <- false;
				foodObjective <- nil;
				write personName+":eating";
			}
		}
	}
	
	action updateInfoObjective{
		float bestDistance <- 10000.0;
		loop counter from:0 to: numberOfInfoCenters-1 {
			InformationCenter objective <- InformationCenter[counter];
			float distance <- norm(objective.location - location);
			if (distance < bestDistance){
				bestDistance <- distance;
				infoObjective <- objective.location;
			}
		}	
	}
	
	action setName(int num) {
		personName <- "Person " + num;
	}
}

species Security skills: [moving]{
	point infoObjective <- nil;
	string personName <- "Undefined";
	string badGuyName <- nil;
	Guest target <- nil;
	
	aspect base {
		draw circle(3) color:rgb("grey");
	}
	
	
	reflex move{
		if (badGuyName != nil) {
			loop counter from: 0 to: numberOfGuests-1 {
        		Guest my_agent <- Guest[counter];
        		if (my_agent.personName = badGuyName){
        			target <- my_agent;
        		}	
			}
			if (!(target = nil)){
				if (target.alive){
					do goto target:target.location;
					write personName+":moving to "+badGuyName;
				} else{
					write "Bad guy already dead";
					badGuyName <- nil;
					infoObjective <- nil;
				}
			}
		} else if(!(infoObjective = nil)) {
			do goto target: infoObjective;
			write personName+" going to info";
				
		}
		else {
			do wander;
			write personName+":wandering";
			}
			
	}
		
	reflex getBadGuyName when: !empty(InformationCenter at_distance infoDistanceThreshold) and (badGuyName = nil) {
		write personName+":Asking for bad guy name!";
		list infoCentersNearMe <- InformationCenter at_distance infoDistanceThreshold;
		ask infoCentersNearMe[0]{
			myself.badGuyName <- self.badGuyName;
			self.badGuyName <- nil;
			self.assigned <- false;
			myself.infoObjective <- nil;
			write myself.personName+":New  bad guy found: " + myself.badGuyName;
		}
		
		
	}
	
	
	action setName(int num) {
		personName <- "Cop " + num;
		write personName+" created";
	}
}

species Store{
	string type;
	
	aspect base {
		rgb agentColor <- rgb("grey");
		
		if (type = "food"){
			agentColor <- rgb("red");
		} else if (type = "drink") {
			agentColor <- rgb("blue");
		}
		draw triangle(3) color:agentColor;
	}	
}

species InformationCenter{
	point recommendedFood <- nil;
	point recommendedDrink <- nil;
	string infoName <- "Undefined";
	string badGuyName <- nil;
	bool assigned <-false;
	
	aspect base {
		draw square(1) color:rgb("black");
	}
	
	reflex setClosestStores{
		int index__food_store <- rnd(0, numberOfStoresFood-1);
		Store store <- Store[index__food_store];
		recommendedFood <- store.location;
		/*write infoName+":Recommended Food position: " + recommendedFood;*/
		
		int index__drink_store <- rnd(numberOfStoresFood,numberOfStoresFood+numberOfStoresDrink-1);
		store <- Store[index__drink_store];
		recommendedDrink <- store.location;
		/* write infoName+":Recommended Drink position: " + recommendedDrink; */
	}
	
	reflex reportBadGuy when: !empty(Guest at_distance infoDistanceThreshold){
		list guestsNearMe <- Guest at_distance infoDistanceThreshold;
		if (!(guestsNearMe[0].good)){
			badGuyName <- guestsNearMe[0].personName;
			Security cop <- Security[securityCounter mod numberOfSecurity];
			cop.infoObjective <- location;
			securityCounter <- securityCounter+1;
			write "Bad Guy Name: "+badGuyName;
		}
		
	}
	
	action setName(int num) {
		infoName <- "Info Center " + num;
	}
}

experiment FestivalExperiment type:gui {
	output {
		display Festival {
			// Display the species with the created aspects
			species Guest aspect:base;
			species Store aspect:base;
			species InformationCenter aspect:base;
			species Security aspect:base;
		}
	}
}
