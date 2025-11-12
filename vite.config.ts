import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],

	// Allow previewing the app when loaded from this host
	preview: {
		allowedHosts: ['nsfw.7thseraph.org']
	}
});
