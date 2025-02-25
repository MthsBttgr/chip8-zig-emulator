//chip8 emulation relevant
pub const rows: i32 = 32;
pub const cols: i32 = 64;

pub var cell_width: i32 = 15;
pub var cell_height: i32 = 15;

pub var set_VX_to_VY_before_shift: bool = true;
pub var treat_jump_as_BNNN = true;
pub var increment_I_on_store_load = true;
pub var clear_VF_after_logic_instructions: bool = true;

pub var instructions_pr_frame: i32 = 20;

//Display settings
pub var show_grid: bool = true;
pub var show_fps: bool = false;
pub var show_code_during_step_through: bool = false;
pub var show_tooltips: bool = true;

pub var error_msg: [:0]const u8 = "Errors:";

// Emulator state
pub var paused: bool = false;
pub var step_through = false;
pub var step_right = false;
pub var step_left = false;
