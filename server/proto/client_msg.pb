
�
client_msg.proto
client_msg"*
ReqLogin
id (Rid
pw (	Rpw"6
ResLogin
code (Rcode
result (	Rresult"

ReqEnter"6
ResEnter
code (Rcode
result (	Rresult"


ball
id (Rid
x (Rx
y (Ry
size (Rsize
speed (Rspeed
speedx (Rspeedx
speedy (Rspeedy"&
ReqShift
x (Rx
y (Ry"*
ResShift
b (2.client_msg.ballRb"

id (Rid"*
InfEnter
b (2.client_msg.ballRb"5
InfBallList&
balls (2.client_msg.ballRballs"F
food
id (Rid
x (Rx
y (Ry
size (Rsize"5
InfFoodList&
foods (2.client_msg.foodRfoods"5
InfMove
id (Rid
x (Rx
y (Ry"4

InfAddFood&
foods (2.client_msg.foodRfoods"B

InfEatFood
id (Rid
fid (Rfid
size (Rsize