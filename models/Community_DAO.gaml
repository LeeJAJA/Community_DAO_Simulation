/**
* Name: Community_DAO
* Based on the internal skeleton template. 
* Author: Jiajie
* Tags: 
*/

model Community_DAO

import "Community_DAO.gaml"

global {
	//ENVIRONMENT
	float step <- 1 #day;
	date starting_date <-date([2022,5,4,7,30]);
	
	/** Insert the global definitions, variables and actions here */
	int nb_mines <- 10;
	int nb_people <- 1000;
	int nb_DAO_outsider <- 1000;
	
	float prob_normal_to_redevelopment <- 1/200 ;
	float prob_normal_to_rehabilitation <- 1/500 ;
	float proposal_cycle <- 1#month;
	float building_status_update_cycle <- 1#month;
	
	int value1 <- 50;
	int value2 <- 75312;
//	float price <- 389.7000 update: price*0.99+20*gauss(0, 1);

	float price <- 389.7000 update: price*1+20*gauss(0, 2);
	float price2 <- 389.7000 update: price2*0.99+20*gauss(0, 2);
	
	float building_price_trend;
	
	// building category
	map<string,rgb> color_per_category <- [ "Hub"::rgb("#8A4B4B"), "Restaurant"::rgb("#536A8D"), "Night"::rgb("#4B493E"),"GP"::rgb("#4B493E"), "Cultural"::rgb("#4B493E"), "Shopping"::rgb("#4B493E"), "HS"::rgb("#4B493E"), "Uni"::rgb("#4B493E"), "O"::rgb("#4B493E"), "R"::rgb("#222222"), "Park"::rgb("#68805F"), "SAT"::rgb("#4B493E"), "stop"::rgb("#4B493E")];	
	map<string, int> buildings_distribution <- map(color_per_category.keys collect (each::0));
	list<string> category_pool <- list(color_per_category.keys);
	
	// GIS data
	string GISFolder <- "./../includes/";
	file<geometry> buildings_shapefile <- file<geometry>(GISFolder+"/Buildings.shp");
	geometry shape <- envelope(buildings_shapefile);    
	
	action import_shapefiles {
		create building from: buildings_shapefile with: [usage::string(read ("Usage")), category::string(read ("Category"))]{
			color <- color_per_category[category];									
			area <- shape.area;
			
			if (flip(prob_normal_to_rehabilitation)) {
				status <- "awaiting_rehabilitation";
			} else
			if (flip(prob_normal_to_redevelopment)) {
				status <- "awaiting_redevelopment";
			}
		}
	}
	
	// B
	predicate house_prices_rise <- new_predicate("house_prices_rise");
    predicate house_prices_fall <- new_predicate("house_prices_fall");
//    predicate maintain_current_status <- new_predicate("maintain_current_status");

    // D&I
	predicate vote_for_buy <- new_predicate("vote_for_buy");
	predicate vote_for_sell <- new_predicate("vote_for_sell");
	predicate proppose_to_buy <- new_predicate("proppose_to_buy");
	predicate propose_to_sell <- new_predicate("propose_to_sell");
	predicate maintain_current_status <- new_predicate("maintain_current_status");

	
	init {
		do import_shapefiles;
		create people number: 3;
	}
	
	// indicators tracking
	reflex update_buildings_distribution_counter{
		buildings_distribution <- map(color_per_category.keys collect (each::0));
		ask building{
			buildings_distribution[usage] <- buildings_distribution[usage]+1;
		}
	}
}


species people control: simple_bdi{
	int tokens <- 0;
	
	bool is_DAO_member;
	float confidence_in_DAO;
	string knowledge_level <- "medium" among: ["low", "medium", "high"];
	int risk_tolerance <- 2 among: [1, 2, 3];
	
	
	perceive target: people  {
    	socialize liking: 1;
    }
    
	// DAO engagement
	action join_DAO {
		is_DAO_member <- true;
	}
	action exit_DAO {
		is_DAO_member <- false;
	}
	
	// trading
	action buy_token {}
	action sell_token {}
	
	// actions between building and token
	action tokenize_private_hosue {}
	action maintain_building {}
	
	// actions on macro DAO asset operation
	action propose_buy_building {}
	action propose_sell_building {}
	
//	reflex buy {
//		value1 <- value1 + rnd (20);
//		ask one_of(building where (each.category = "R")) {
//			color <- #yellow;
//		}
//	}
//	
//	reflex sell {
//		value1 <- value1 - rnd (value1/100);
//		ask one_of(building where (each.category = "R")) {
//			color <- #green;
//		}
//	}
	
	reflex discuss {
	}
	
	// actions on macro renting
	action propose_rent_hosue {}
	action propose_change_rentablity {}
	// actions on micro renting
	action rent_hosue {}
	action propose_rent_candidate {}
}

species building {
	string usage;
	string category;
	float area;	
	rgb color <- #grey;

	string status <- "normal" among: ["normal", "under_construction", "awaiting_rehabilitation", "awaiting_redevelopment"];
	
	
	reflex update_building_status when: every(building_status_update_cycle){
		if (status = "normal")  {
			if (flip(prob_normal_to_rehabilitation)) {
				status <- "awaiting_rehabilitation";
			} else
			if (flip(prob_normal_to_redevelopment)) {
				status <- "awaiting_redevelopment";
			}
		} 
	}
	
	// display
	aspect default {
		if (status = "awaiting_renewal") {
			draw shape color: #white ;
		} else {
			draw shape color: color ;
		}
	}
}





experiment DAOSim type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map draw_env: false background: #black refresh:every(1#cycle){
			species building;
		}
		display chart_display  background: #black {

            graphics "Current Time" {
				draw 'Current Time：' + string(current_date.year) + "-" + string(current_date.month) +"-" + string(current_date.day) color: #white  font: font("Helvetica", 25, #italic) at: {world.shape.width*0.1 ,world.shape.height*0.2};
			}
			
//			chart "my_chart" type: histogram background: #black axes:#white color:#white size: {0.5,1} position: {0, 0}{
//	        datalist (distribution_of(people collect each.fiat_money,20,0,100) at "legend") 
//	            value:(distribution_of(people collect each.fiat_money,20,0,100) at "values");      
//	        }
//	        chart "House Price" type: series background: #black axes:#white color:#white size: {1,0.5} position: {0, 0}{
//	            data "hosue price A" value: price color: #red;
//	            data "hosue price B" value: price2 color: #blue;
//	        }
//	        chart "People Ratio" type: pie style: exploded background: #black axes:#white color:#white size: {0.5, 0.5} position: {0, 0.5}{
//		           data "DAO Member" value: value1 color: #magenta ;
//		           data "Outsider" value: value2 color: #blue ;
//		      }
//		     chart "People Ratio" type: pie style: exploded background: #black axes:#white color:#white size: {0.5, 0.5} position: {0.5, 0.5}{
//		           data "DAO Member" value: value1+0.05*value2 color: #magenta ;
//		           data "Outsider" value: value2 color: #blue ;
//		      }
		}
	}
}
