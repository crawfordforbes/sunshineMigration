

var getPics = function(){
	$.get("/pics", function(data){
		var excludedPics = data.filter(function(pic){
		return pic.carousel === 0
	})
	var includedPics = data.filter(function(pic){
		return pic.carousel > 0
	})
	var pictures = includedPics.sort(function(a, b){
		return a.carousel - b.carousel
	})

		lister(pictures);
		addListeners(pictures);
	})
}
var lister = function(pics){
	$("#js").html('')
	


	var html = ""
	for(var i = 0; i<pics.length; i++){
		var newCar = i + 1;

		var	moveButton = '<button class="picmove" id="'+pics[i].id + '/'+i+'">move</button>'
		if(i % 8 === 0){
			var pageBreak = i / 8 + 1;
			html += '<div><p>Page '+ pageBreak + '</p></div>'
		}
		
		html += '<li><a href="./pic/' + pics[i].id +'"><img class="thumb" src="../' + pics[i].url +'"></a><p>http://www.sunshinenights.com/' + pics[i].url +'</p><p>This is currently pic number ' + newCar +' out of '+pics.length+'</p><input id="input'+pics[i].id + '" placeholder="enter order number here">'+moveButton+'</li><div style="border-bottom: 1px red dashed; margin-bottom: 5px;"></div>'
	}
	$("#js").html(html)
}
var addListeners = function(pictures){
	$(".picmove").click(pictures, function(e){
		e.preventDefault();
		var pics = e.data;
		var id = parseInt(e.target.id.split("/")[0]);
		var oldCar = parseInt(e.target.id.split("/")[1]);

		var car = parseInt($("#input"+id).val());
		if(isNaN(car) || car < 1 || car > pics.length){
			alert("please enter a number between 1 and " + pics.length + " only, thanks!")
			return
		}
		console.log(pics)
		var tempPics = pics.splice(oldCar, 1)

		pics.splice(car - 1, 0, tempPics[0])

		for(var c = 0; c < pics.length; c++){
			pics[c].carousel = c + 1
		}
		console.log(pics)
		$.ajax({
			method: "PUT",
			url: "/admin/pics",
			data: { pics: JSON.stringify(pics) },
			success: function(data){
				console.log("pics updated")
				getPics()
			}
		})
			// var onlyNum = true
			// for(var i = 0; i<data.length; i++){
			// 	if (data[i].id === id){
			// 		data[i].carousel = car
			// 	}

				
			// 	if(data[i].id != id && data[i].carousel > oldCar){
			// 		data[i].carousel--

			// 	}
			// }
			// for(var j=0; j<data.length; j++){
			// 	if (car >= 1 && data[j].carousel === car && data[j].id != id){
			// 		onlyNum = false
			// 	}
			// 	if(!onlyNum && data[j].id != id && data[j].carousel >= car){
			// 		data[j].carousel++
			// 	}
			// }




	})
}

window.onload = getPics()