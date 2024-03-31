//Docking error flags
#define DOCKING_SUCCESS				0
#define DOCKING_BLOCKED				(1<<0)
#define DOCKING_IMMOBILIZED			(1<<1)
#define DOCKING_AREA_EMPTY			(1<<2)
#define DOCKING_NULL_DESTINATION	(1<<3)
#define DOCKING_NULL_SOURCE			(1<<4)

//Rotation params
#define ROTATE_DIR      (1<<0)
#define ROTATE_SMOOTH   (1<<1)
#define ROTATE_OFFSET   (1<<2)

#define SHUTTLE_DOCKER_LANDING_CLEAR 1
#define SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT 2
#define SHUTTLE_DOCKER_BLOCKED 3
