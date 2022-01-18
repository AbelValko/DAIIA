/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Abel Valko, Kishore Kumar
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
		int numberOfParticipants <- 5;
		int numberOfAuctioneers <- 1;
		
		list parts;
		
		init{
			list items <- ["shirt", "poster"];
			list meanPrices <- [300.0, 500.0];
			list stds <- [80.0, 120.0];
			float chanceOfInterest <- 0.5;
			
			create Auctioneer number:1 with:(merchType:"shirt", initialOffer:600, increment:60, lowestPrice:280);
			create Auctioneer number:1 with:(merchType:"poster", initialOffer:1200, increment:100, lowestPrice:400);
			create Participant number: numberOfParticipants returns: ps;
			
			write '---Simulation started with ' + numberOfParticipants + ' participants and ' + numberOfAuctioneers + ' auctioneers---';

			parts <- ps; //list of all participants

			write "---Participant interests and prices---";
			loop p from:0 to:numberOfParticipants-1{
				map<string,float> myPrices <- nil;
				loop i from:0 to:length(items)-1{
					bool  take <- flip(chanceOfInterest);
					if take{
						add gauss_rnd(meanPrices[i], stds[i]) at: items[i] to:myPrices;
					}
				}
				Participant[p].myPrices <- myPrices;
				write "Participant " + p;
				write myPrices;
			}
		}
}

species Auctioneer skills: [fipa] {
	
	string merchType;
	float initialOffer;
	float increment;
	float lowestPrice;
	
	float currentOffer <- initialOffer;
	int auctionCycleCounter <- 0;
	bool deal <- false;
	string buyer <- nil;
	
	reflex sendRequest when:(time = 1){
		//Sends request to all participants to join auction.	
		write name + ': Starting auction';
			do start_conversation (to::parts, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start_auction', merchType]);	//Merch hardcoded, contents list format hardcoded	
	}
	
	reflex initiate_cfp when: (time = 2) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		currentOffer <- initialOffer;
		auctionCycleCounter <- auctionCycleCounter + 1;
		if currentOffer >= lowestPrice{ //NOT NEEDED
			write "Initiating for the price:" + currentOffer;
			loop p over:parts{
				do start_conversation (to::p, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Propose_price',merchType,currentOffer]);	
			}			
		}
		else{
			write "Ending the auction as the price "+currentOffer+" is too low.";		
		}
	}
	
	reflex refusals_handler when: (empty(proposes) and !empty(refuses) and !deal) {
		write '(Time ' + time + '): ' + name + ' no proposals';
		currentOffer <- initialOffer - increment*auctionCycleCounter;
		auctionCycleCounter <- auctionCycleCounter + 1;
		if currentOffer >= lowestPrice{
			loop r over: refuses {
				write '\t' + name + ' receives a refusal message from ' + agent(r.sender).name + ' with content ' + r.contents ;
				do cfp message: r contents: ['Propose_price',merchType,currentOffer];
			}
			write "New proposal for the price:" + currentOffer;
		}
		else{
			loop r over: refuses {
				write '\t' + name + ' receives a refusal message from ' + agent(r.sender).name + ' with content ' + r.contents ;
				do end_conversation message:r contents:['End_auction', merchType, currentOffer];
			}
			write "Ending the auction as the price "+currentOffer+" is too low.";
		}
		
		
		}
		
	reflex proposals_handler when: (!empty(proposes) and !deal) {
		write '(Time ' + time + '): ' + name + ' received proposals';
		int winnerProp <- rnd(0,length(proposes)-1);
		int counter <- 0;
		loop p over: proposes {
				write '\t' + name + ' receives a proposal message from ' + agent(p.sender).name + ' with content ' + p.contents ;
				if (counter = winnerProp){
					write '\t' + name + ' striking a deal with ' + agent(p.sender).name;
					do accept_proposal message: p contents: ['Deal!!'] ;
					buyer <- agent(p.sender).name;
					deal <- true;
				} else{
					write '\t' + name + ' rejecting the deal with' + agent(p.sender).name;
					do reject_proposal message: p contents: ['Already struck a deal!!'] ;
				}
				counter <- counter+1;
			}
		}
}

species Participant skills: [fipa]{
	
	map<string,float> myPrices <- nil;
	
	reflex respond_to_cfps when: !empty(cfps) {
		loop prop over:cfps{
			list conts <- prop.contents;
			string item <- conts[1];
			write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(prop.sender).name + ' with content ' + prop.contents;
			float myPrice <- myPrices[item];
			if myPrice != 0{
				float currentOffer <- conts[2];
				write '\t' + name + ' sends message to ' + agent(prop.sender).name;
				if currentOffer <= myPrice {
					write '\t I am buying it for '+currentOffer;
					do propose message: prop contents: ['Accept'] ;
				} else{
					write '\t Price too high';
					do refuse message: prop contents: ['Reject'] ;
				}
			} else {
				//do end_conversation message: proposalFromAuctioneer contents: ['Not interested'];
				write '(Time ' + time + '):' + name + ' not interested in item';
			}	
		}
	}
	
	reflex receive_inform_messages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		loop i over: informs {
			write '\t' + name + ' receives a inform message from ' + agent(i.sender).name + ' with content ' + i.contents ;
		}
	}
	
	reflex receive_reject_proposals when: !empty(reject_proposals) {
		message r <- reject_proposals[0];
		write '(Time ' + time + '): ' + name + ' received a reject_proposal message from ' + agent(r.sender).name + ' with content ' + r.contents;
		do end_conversation message:r contents:['That is too bad'];
	}
	
	reflex receive_accept_proposals when: !empty(accept_proposals) {
		message a <- accept_proposals[0];
		write '(Time ' + time + '): ' + name + ' received an accept_proposal message from ' + agent(a.sender).name + ' with content ' + a.contents;
		do end_conversation message:a contents:['Awesome'];
	}
}

experiment MyExperiment {
	
}

