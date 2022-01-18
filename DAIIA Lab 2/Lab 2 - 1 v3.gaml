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
			create Auctioneer number:numberOfAuctioneers;
			create Participant number: numberOfParticipants returns: ps;
			
			parts <- ps; //list of all participants
			
			list preferredPrices <- [400, 420, 210, 350, 375]; //Could be randomized, some norm + gaussian deviation
			
			Participant[0].preferredPrice <- preferredPrices[0];
			Participant[1].preferredPrice <- preferredPrices[1];
			Participant[2].preferredPrice <- preferredPrices[2];
			Participant[3].preferredPrice <- preferredPrices[3];
			Participant[4].preferredPrice <- preferredPrices[4];
			
			write 'Simulation started with ' + numberOfParticipants + ' participants and ' + numberOfAuctioneers + ' auctioneers';
		}
}

species Auctioneer skills: [fipa] {
	
	int maxAuctionCycles <- 5;
	float initialOffer <- 500.0;
	float currentOffer <- 500.0;
	float lowestPrice <- 200.0;
	float increment <- (initialOffer - lowestPrice)/maxAuctionCycles;
	int auctionCycleCounter <- 0;
	bool deal <- false;
	string buyer <- nil;
	
	reflex sendRequest when:(time = 1){
		//Sends request to all participants to join auction.	
		write name + ': Starting auction';
			do start_conversation (to::parts, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start_auction', 'Merch']);	//Merch hardcoded, contents list format hardcoded	
	}
	
	reflex initiate_cfp when: (time = 2) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		currentOffer <- initialOffer;
		auctionCycleCounter <- auctionCycleCounter + 1;
		if currentOffer >= lowestPrice{
			write "Initiating for the price:" + currentOffer;
			do start_conversation (to::parts, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Propose_price','Merch',currentOffer]); 			
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
				do cfp message: r contents: ['Propose_price','Merch',currentOffer];
			}
			write "New proposal for the price:" + currentOffer;
		}
		else{
			loop r over: refuses {
				write '\t' + name + ' receives a refusal message from ' + agent(r.sender).name + ' with content ' + r.contents ;
				do end_conversation message:r contents:['End_auction', 'Merch', currentOffer];
			}
			write "Ending the auction as the price "+currentOffer+" is too low.";
		}
		
		
		}
		
	reflex proposals_handler when: (!empty(proposes) and !deal) {
		write '(Time ' + time + '): ' + name + ' received proposals';
		int counter <- 0;
		loop p over: proposes {
				write '\t' + name + ' receives a proposal message from ' + agent(p.sender).name + ' with content ' + p.contents ;
				if (counter = 0){
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
		loop r over: refuses {
			do end_conversation message:r contents:['End_auction', 'Merch'];
		}
	}
}

species Participant skills: [fipa]{
	
	int preferredPrice <- nil;
	int currentOffer <- nil;
		
	reflex receive_inform_messages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		
		loop i over: informs {
			write '\t' + name + ' receives a inform message from ' + agent(i.sender).name + ' with content ' + i.contents ;
			do end_conversation message:i contents:["Understood"];
		}
	}
	
	reflex respond_to_proposals when: !empty(cfps) {
		message proposalFromAuctioneer <- cfps[0];
		list conts <- proposalFromAuctioneer.contents;
		currentOffer <- conts[2];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromAuctioneer.sender).name + ' with content ' + proposalFromAuctioneer.contents;
		//write '\t' + name + ' sends a propose message to ' + agent(proposalFromAuctioneer.sender).name;
		if currentOffer <= preferredPrice {
			write 'I am buying it for '+currentOffer;
			do propose message: proposalFromAuctioneer contents: ['Accept'] ;
		} else{
			//write 'I would like to buy it for '+preferredPrice;
			write "Price is too high, rejecting";
			do refuse message: proposalFromAuctioneer contents: ['Reject'] ;
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

