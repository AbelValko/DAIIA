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
	
	int numberOfGuests <- 10;
	int numberOfStoresFood <- 3;
	int numberOfStoresDrink <- 4;
	int numberOfInfoCenters <- 3;
	
	float hungerProb <- 0.01;
	float thirstProb <- 0.015;
	
	int infoDistanceThreshold <- 0;
	int consumeDistanceThreshold <- 0;
	
	list foodLocations <- nil;
	list drinkLocations <- nil;
	
	init {
		create Guest number:numberOfGuests;
		create Store number:numberOfStoresFood with: (type:"food");
		create Store number:numberOfStoresDrink with: (type:"drink");
		create InformationCenter number:numberOfInfoCenters;
	
		loop counter from: 0 to: numberOfInfoCenters-1 {
			InformationCenter myAgent <- InformationCenter[counter];
			//myAgent.setClosestFood();
			myAgent <- myAgent.setClosestStores();
		}
	}	
}

species Guest skills: [moving]{
	bool hungry <- false;
	bool thirsty <- false;
	
	point foodObjective <- nil;
	point drinkObjective <- nil;
	point infoObjective <- nil;
	
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
			hungry <- flip(hungerProb);
			if hungry {
				write "I'm hungry";
				do updateInfoObjective;	
			}
		}
		if (!thirsty){
			thirsty <- flip(thirstProb);
			if thirsty {
				write "I'm thirsty";
				do updateInfoObjective;
			}
		}
	}
	
	reflex move{
		if (drinkObjective != nil) {
			do goto target:drinkObjective;
			//write "moving to drink";
		} else if (foodObjective != nil) {
			do goto target:foodObjective;
			//write "moving to food";
		} else if (hungry or thirsty){
			do goto target:infoObjective;
			//write "moving to info";
		} else {
			do wander;
			write "wandering";
		}
	}
		
	reflex checkForInfo when: ((hungry or thirsty) and ((drinkObjective = nil)  or (foodObjective = nil))) and !empty(InformationCenter at_distance infoDistanceThreshold) {
		write "Asking for directions!";
		list infoCentersNearMe <- InformationCenter at_distance infoDistanceThreshold;
		ask infoCentersNearMe[0]{
			if myself.hungry{
				myself.foodObjective <- self.closestFood;
				write "New food objective found: " + myself.foodObjective;
			}
			if myself.thirsty{
				myself.drinkObjective <- self.closestDrink;
				write "New drink objective found: " + myself.drinkObjective;
			}
		}
	}
	
	reflex consumeStuff when: !empty(Store at_distance consumeDistanceThreshold){
		list storesNearMe <- Store at_distance consumeDistanceThreshold;
		if thirsty {
			if storesNearMe[0].type = "drink"{
				thirsty <- false;
				drinkObjective <- nil;
				write "drinking";
			}
		}
		if hungry {
			if storesNearMe[0].type = "food"{
				hungry <- false;
				foodObjective <- nil;
				write "eating";
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
	point closestFood <- nil;
	point closestDrink <- nil;
	
	aspect base {
		draw square(1) color:rgb("black");
	}
	
	action setClosestStores{
		float bestDistance <- 10000.0;
		loop counter from:0 to: numberOfStoresFood-1 {
			Store store <- Store[counter];
			float distance <- norm(store.location - location);
			if (distance < bestDistance){
				bestDistance <- distance;
				closestFood <- store.location;
			}
		}
		write "Closest Food found: " + closestFood;
		
		bestDistance <- 10000.0;
		loop counter from:numberOfStoresFood to: numberOfStoresDrink+numberOfStoresFood-1 {
			Store store <- Store[counter];
			float distance <- norm(store.location - location);
			if (distance < bestDistance){
				bestDistance <- distance;
				closestDrink <- store.location;
			}
		}
		write "Closest Drink found: " + closestDrink;
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
