/*呼び出して使用するメソッドを定義*/
zenra = {};

/*
helloWorld - サンプルメソッド
*/
zenra.helloWorld = function(name) {
	alert('Hello ,' + name);
};

/*
showDialog - ダイアログを表示する
*/
zenra.showDialog = function() {
	$( "#dialog" ).dialog({
		modal: true,
		height: "auto",
		width: 480,
	});
};
