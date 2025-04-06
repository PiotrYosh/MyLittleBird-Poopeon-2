using Godot;
using System;

public partial class CharacterMovement : CharacterBody3D
{
	[Export] private float walkSpeed = 3.0f;
	[Export] private float runSpeed = 6.0f;
	[Export] private float crouchSpeed = 1.5f;
	[Export] private float sneakSpeed = 2.0f;
	[Export] private float jumpVelocity = 5.0f;
	[Export] private float gravity = 9.8f;
	
	private AnimationPlayer anim;
	private Vector3 velocity = Vector3.Zero;
	
	public override void _Ready()
	{
		anim = GetNode<AnimationPlayer>("../AnimationPlayer");
	}
	
	public override void _PhysicsProcess(double delta)
	{
		Vector3 direction = Vector3.Zero;
		float speed = walkSpeed;
		
		if (!IsOnFloor())
		{
			velocity.Y -= gravity * (float)delta;
		}
		
		if (Input.IsActionPressed("move_forward")) direction -= Transform.Basis.Z;
		if (Input.IsActionPressed("move_backward")) direction += Transform.Basis.Z;
		if (Input.IsActionPressed("move_left")) direction -= Transform.Basis.X;
		if (Input.IsActionPressed("move_right")) direction += Transform.Basis.X;
		
		if (direction != Vector3.Zero)
		{
			direction = direction.Normalized();
			
			if (Input.IsActionPressed("sprint"))
			{
				speed = runSpeed;
				anim.Play("Run");
			}
			else if (Input.IsActionPressed("crouch"))
			{
				speed = crouchSpeed;
				anim.Play("Crouch");
			}
			else if (Input.IsActionPressed("sneak"))
			{
				speed = sneakSpeed;
				anim.Play("Sneak");
			}
			else
			{
				anim.Play("Walk");
			}
		}
		else
		{
			anim.Play("Idle");
		}
		
		if (Input.IsActionJustPressed("jump") && IsOnFloor())
		{
			velocity.Y = jumpVelocity;
			anim.Play("Jump");
		}
		
		velocity.X = direction.X * speed;
		velocity.Z = direction.Z * speed;
		
		MoveAndSlide();
	}
}
