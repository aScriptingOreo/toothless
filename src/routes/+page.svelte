<script lang="ts">
	import { onMount, onDestroy } from 'svelte';

	export const prerender = true;

	let scale = 1;
	let fontSize = 16;
	let isFirstClick = true;
	let btnBg = 'purple';
	let btnColor = 'white';
	let clickCount = 0;
	let dragonCount = 0;
	let showButton = true;
		// large list of font-families (many may not be installed locally; browser will pick closest fallback)
		const fonts = [
			'Arial', 'Verdana', 'Helvetica', 'Tahoma', 'Trebuchet MS', 'Times New Roman', 'Georgia', 'Garamond', 'Courier New', 'Brush Script MT',
			'Impact', 'Comic Sans MS', 'Palatino Linotype', 'Segoe UI', 'Lucida Sans', 'Candara', 'Futura', 'Optima', 'Gill Sans', 'Century Gothic',
			'Times', 'Serif', 'Sans-Serif', 'Monaco', 'Consolas', 'Lucida Console', 'Brush Script', 'Hiragino Kaku Gothic Pro', 'Meiryo', 'MS PGothic',
			'Noto Sans', 'Noto Serif', 'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Oswald', 'Raleway', 'PT Sans', 'Merriweather', 'Source Sans Pro',
			'Ubuntu', 'Droid Sans', 'Cabin', 'Playfair Display', 'Bitter', 'Arvo', 'Nunito', 'Karla', 'Poppins', 'Work Sans'
		];

		// translations of "more" in many languages — cycles on each click
		// NOTE: Hebrew translations have been removed per user request
		const translations = [
			'MORE','MÁS','PLUS','MEHR','MAIS','PIÙ','更多','もっと','더','Еще','VOTE','ANCORA','MERE','YHTEEN','MERE','DAHA','もっと','MER',
			'MUCHO','MAI','MER','もっと','ANIM','DALEJ','さらに','MEER','MERE','MEHR','ANCORA','还要','もっと','더','HIZI','JISHIN','MAL','TILAA','BŐVEBBEN',
			'MER','MER','रम','আরও','আর','অধিক','ጨምር','もっと','더'
		];

		let fontIndex = 0;
		let translationIndex = 0;

		let audio: HTMLAudioElement | null = null;
		let bodyClickHandler: () => void;

		function padHex(hex: string) {
			return hex.length === 3 ? hex.split('').map(c => c + c).join('') : hex;
		}

		function getRandomHexColor() {
			return '#' + Math.floor(Math.random() * 0xffffff).toString(16).padStart(6, '0');
		}

		function getReadableTextColor(hexColor: string) {
			// strips # if present
			let hex = hexColor.replace('#', '');
			if (hex.length === 3) hex = padHex(hex);
			const r = parseInt(hex.substring(0, 2), 16);
			const g = parseInt(hex.substring(2, 4), 16);
			const b = parseInt(hex.substring(4, 6), 16);
			// YIQ formula for contrast
			const yiq = (r * 299 + g * 587 + b * 114) / 1000;
			return yiq >= 128 ? '#000000' : '#ffffff';
		}

	onMount(() => {
		audio = new Audio('/assets/music.mp3');
		audio.volume = 0.1;

		bodyClickHandler = () => {
			const overlay = document.getElementById('overlay');
			if (overlay) overlay.style.backgroundColor = '#' + Math.floor(Math.random() * 16777215).toString(16);
		};

		// attach to document.body so clicks anywhere (outside the button) affect the overlay
		document.body.addEventListener('click', bodyClickHandler);

		// set initial random button color and readable text color (Svelte-managed)
		const initialColor = getRandomHexColor();
		btnBg = initialColor;
		btnColor = getReadableTextColor(initialColor);

	// particle DOM pool setup
	createPool();
	});

	onDestroy(() => {
	    if (typeof document !== 'undefined' && bodyClickHandler) document.body.removeEventListener('click', bodyClickHandler);
	});

	function handleButtonClick(event: MouseEvent) {
		event.stopPropagation(); // prevent the body click handler from firing

		if (isFirstClick) {
			// On first click, hide button and show dragon count
			showButton = false;
			isFirstClick = false;

			if (audio) {
				void audio.play();
			}

			// spawn one dragon
			spawnDragon();
			clickCount++;
		}
	}


// ------------------- Dragon particle system (DOM with pooling) -------------------
let particleContainer: HTMLDivElement | null = null;
const MAX_DOM_PARTICLES = 5000;
let imgPool: HTMLImageElement[] = [];
let activeElements: Set<HTMLImageElement> = new Set();

interface DragonState {
	el: HTMLImageElement;
	size: number;
	x: number;
	y: number;
	dx: number;
	dy: number;
	direction: 'left-to-right' | 'right-to-left';
	duration: number; // animation duration in ms
	speedMultiplier: number; // ±0.2 speed variation
	startTime: number;
	animationFrameId?: number;
	nextSpawnTimeoutId?: number;
}

const dragonStates = new Map<HTMLImageElement, DragonState>();

function createPool() {
	particleContainer = document.createElement('div');
	particleContainer.id = 'particleContainer';
	particleContainer.style.position = 'fixed';
	particleContainer.style.left = '0';
	particleContainer.style.top = '0';
	particleContainer.style.width = '100%';
	particleContainer.style.height = '100%';
	particleContainer.style.zIndex = '5';
	particleContainer.style.pointerEvents = 'none';
	document.body.appendChild(particleContainer);

	for (let i = 0; i < MAX_DOM_PARTICLES; i++) {
		const img = document.createElement('img');
		img.src = '/assets/anim.png';
		img.style.position = 'absolute';
		img.style.left = '-9999px';
		img.style.top = '-9999px';
		img.style.width = '1px';
		img.style.height = '1px';
		img.style.opacity = '0';
		img.style.willChange = 'transform, opacity';
		img.style.transformOrigin = 'center center';
		img.style.pointerEvents = 'none';
		particleContainer.appendChild(img);
		imgPool.push(img);
	}
}

function spawnDragon() {
	if (!particleContainer) return;
	if (imgPool.length === 0) return; // pool exhausted

	const el = imgPool.pop()!;
	
	// clean up any previous state
	const prevState = dragonStates.get(el);
	if (prevState?.animationFrameId) cancelAnimationFrame(prevState.animationFrameId);
	if (prevState?.nextSpawnTimeoutId) clearTimeout(prevState.nextSpawnTimeoutId);

	activeElements.add(el);
	dragonCount++;

	// generate all random variables for this dragon instance
	const size = Math.floor(Math.random() * 1960) + 40; // 40-2000px
	const y = Math.floor(Math.random() * Math.max(1, window.innerHeight - size));
	
	// 10% chance to scroll across screen, 90% chance to spawn randomly
	const shouldScroll = Math.random() < 0.1;
	let x = 0;
	let dx = 0;
	let direction: 'left-to-right' | 'right-to-left';
	
	if (shouldScroll) {
		// scroll across screen
		direction = Math.random() > 0.5 ? 'left-to-right' : 'right-to-left';
		if (direction === 'left-to-right') {
			x = -size;
			dx = window.innerWidth + size * 2;
		} else {
			x = window.innerWidth;
			dx = -(window.innerWidth + size * 2);
		}
	} else {
		// spawn randomly on screen
		direction = Math.random() > 0.5 ? 'left-to-right' : 'right-to-left';
		x = Math.floor(Math.random() * Math.max(1, window.innerWidth - size));
		const randomDistance = Math.floor(Math.random() * 200) - 100; // -100 to 100
		dx = direction === 'left-to-right' ? Math.abs(randomDistance) : -Math.abs(randomDistance);
	}
	
	const dy = Math.floor(Math.random() * 160) - 80; // -80 to 80 vertical drift
	const baseDuration = Math.floor(Math.random() * 5000) + 3000; // 3s to 8s
	const speedMultiplier = 0.8 + Math.random() * 0.4; // 0.8 to 1.2 (±0.2 variation)
	const duration = Math.floor(baseDuration / speedMultiplier);
	const delay = Math.floor(Math.random() * 800); // 0 to 800ms
	
	// add unique query parameter to desynchronize APNG animation timing
	const apngDelay = Math.floor(Math.random() * 3000);
	el.src = `/assets/anim.png?t=${Date.now()}_${Math.random()}_delay=${apngDelay}`;

	// apply initial styles
	el.style.width = size + 'px';
	el.style.height = 'auto';
	el.style.left = x + 'px';
	el.style.top = y + 'px';
	el.style.opacity = '1';
	el.style.transform = 'translate3d(0,0,0) scale(1)';
	el.style.transition = 'opacity 0.5s ease';
	el.style.animationDelay = `-${apngDelay}ms`;

	// store dragon state
	const dragonState: DragonState = {
		el,
		size,
		x,
		y,
		dx,
		dy,
		direction,
		duration,
		speedMultiplier,
		startTime: Date.now() + delay
	};
	dragonStates.set(el, dragonState);

	// start animation with delay
	setTimeout(() => {
		animateDragon(el, dragonState);
	}, delay);

	// schedule next spawn when this dragon completes
	const nextSpawnTimeoutId = window.setTimeout(() => {
		completeDragon(el);
	}, duration + delay);

	dragonState.nextSpawnTimeoutId = nextSpawnTimeoutId;
	dragonStates.set(el, dragonState);
}

function animateDragon(el: HTMLImageElement, state: DragonState) {
	const animate = () => {
		if (!activeElements.has(el)) return;

		const elapsed = Date.now() - state.startTime;
		const progress = elapsed / state.duration; // 0 to 1

		if (progress >= 1) {
			// animation complete
			return;
		}

		const currentDx = state.dx * progress;
		const currentDy = state.dy * progress;
		const currentScale = 1 - (progress * 0.4); // 1.0 to 0.6

		el.style.transform = `translate3d(${currentDx}px, ${currentDy}px, 0) scale(${currentScale})`;

		const frameId = window.requestAnimationFrame(animate);
		state.animationFrameId = frameId;
		dragonStates.set(el, state);
	};

	animate();
}

function completeDragon(el: HTMLImageElement) {
	const state = dragonStates.get(el);
	if (!state || !activeElements.has(el)) return;

	// fade out
	el.style.opacity = '0';

	setTimeout(() => {
		if (!activeElements.has(el)) return;

		// clean up
		activeElements.delete(el);
		dragonStates.delete(el);
		dragonCount--;

		// reset for reuse
		el.style.left = '-9999px';
		el.style.top = '-9999px';
		el.style.opacity = '0';
		el.style.transform = 'translate3d(0,0,0) scale(1)';
		el.style.width = '1px';
		el.style.height = '1px';
		el.style.animationDelay = '0ms';
		el.src = '';

		imgPool.push(el);

		// spawn 1-2 new dragons on completion (60% chance for 2nd dragon)
		// this creates the nuclear reactor effect where the animation perpetuates itself
		spawnDragon();
		if (Math.random() > 0.4) {
			// Stagger the second spawn slightly with a random delay to ensure different random variables
			setTimeout(() => {
				spawnDragon();
			}, Math.random() * 50 + 10); // 10-60ms delay
		}
	}, 500); // fade out duration
}

// old canvas cleanup removed (we now use DOM pooled images)
onDestroy(() => {
	// clear any animation frames and timeouts
	dragonStates.forEach((state) => {
		if (state.animationFrameId) cancelAnimationFrame(state.animationFrameId);
		if (state.nextSpawnTimeoutId) clearTimeout(state.nextSpawnTimeoutId);
	});
	dragonStates.clear();
    imgPool.length = 0;
    activeElements.clear();
	if (particleContainer) particleContainer.remove();
});
</script>

<style>
	:global(body) {
		background-color: #000000;
		margin: 0;
		overflow: hidden;
	}

	.page {
		display: flex;
		justify-content: center;
		align-items: center;
		height: 100vh;
		position: relative;
	}

		#myButton {
			z-index: 200000; /* ensure the button renders on top and remains clickable */
			background-color: purple;
			color: white;
			padding: 15px 32px;
			text-align: center;
			text-decoration: none;
		}
	#overlay {
		z-index: 1;
		position: fixed;
		top: 0;
		left: 0;
		width: 100%;
		height: 100%;
		opacity: 0.75;
	}

	#dragonCounter {
		position: fixed;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		z-index: 200001;
		color: white;
		font-weight: bold;
		font-family: monospace;
		text-align: center;
		text-shadow: 0 0 20px rgba(255, 255, 255, 0.8), 0 0 40px rgba(255, 100, 100, 0.6);
		letter-spacing: 4px;
		pointer-events: none;
		transition: font-size 0.1s ease-out;
	}
</style>

	<div class="page">
		<div id="overlay"></div>

		{#if showButton}
		<button id="myButton" on:click={handleButtonClick} aria-label="Trust me, Bro" style="transform: scale({scale}); font-size: {fontSize}px; background-color: {btnBg}; color: {btnColor}">Trust me, Bro</button>
		{:else}
		<div id="dragonCounter" style="font-size: {Math.max(48, dragonCount * 10 + 48)}px">{dragonCount}</div>
		{/if}
	</div>
