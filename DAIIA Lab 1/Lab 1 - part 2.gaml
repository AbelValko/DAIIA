/**
* Name: Lab 1 - basic
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
	int stepCounterVariable <- 0 update: stepCounterVariable+1;
	
	int numberOfGuests <- 1;
	int numberOfStoresFood <- 2;
	int numberOfStoresDrink <- 2;
	int numberOfInfoCenters <- 1;
	
	int infoDistanceThreshold <- 1;
	int consumeDistanceThreshold <- 1;
	
	list foodLocations <- nil;
	list drinkLocations <- nil;
	
	init {
		create Guest number:numberOfGuests;
		create Store number:numberOfStoresFood with: (type:"food");
		create Store number:numberOfStoresDrink with: (type:"drink");
		create InformationCenter number:numberOfInfoCenters;
		
		loop counter from: 1 to: numberOfGuests {
        	Guest my_agent <- Guest[counter - 1];
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
	
	point foodObjective <- nil;
	point drinkObjective <- nil;
	point rememberfood <- nil;
	point rememberdrink <- nil;
	point infoObjective <- nil;
	string personName <- "Undefined";
	
	aspect base {
		rgb agentcolor <- rgb("grey");
		
		if (hungry and thirsty) {
			agentcolor <- rgb("purple");
		} else if (hungry) {
			agentcolor <- rgb("red");
		} else if (thirsty) {
			agentcolor <- rgb("blue");
		} else {
			agentcolor <- rgb("green");
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
		write personName+":Going to info center";
		ask infoCentersNearMe[0]{
		if myself.hungry{
			myself.foodObjective <- self.recommendedFood;
			myself.rememberfood <- myself.foodObjective;
			myself.rememberdrink <- myself.drinkObjective;
			write myself.personName+":New food objective found: " + myself.foodObjective;
		}
		if myself.thirsty{
			myself.drinkObjective <- self.recommendedDrink;
			myself.rememberfood <- myself.foodObjective;
			myself.rememberdrink <- myself.drinkObjective;
			write myself.personName+":New drink objective found: " + myself.drinkObjective;
		}
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
		}
	}
}
